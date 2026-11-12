import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_scanner_config.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// Reads the audio library of the system through Android's MediaStore.
///
/// A path walk cannot see the files of other apps under scoped storage, so
/// the rows come from MediaStore instead: one row per track, already carrying
/// its tags and a playable `content://` address. The native half lives in
/// `MainActivity` (`cn.iouf.tune/media_store`, `listAudio`).
///
/// The directory arguments of the interface are accepted and ignored: the
/// system library is one library, and asking the reader to pick folders on a
/// phone is E3's SAF step, not this one.
class MediaStoreMusicScanner implements CrossPlatformMusicScanner {
  static const MethodChannel _channel = MethodChannel('cn.iouf.tune/media_store');

  /// Logged once: a reader who denied the media permission would otherwise
  /// see the same failure on every startup scan.
  bool _permissionReported = false;

  @override
  bool get addressesSystemLibrary => true;

  @override
  Future<void> init() async {}

  @override
  Future<List<Song>> scanMusic() => _query();

  @override
  Future<List<Song>> scanMusicInDirectory(String directoryPath) => _query();

  @override
  Future<List<Song>> scanMusicInDirectories(List<String> directoryPaths) =>
      _query();

  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async {
    final songs = await _query();
    onProgress(1);
    return songs;
  }

  /// A single path cannot be resolved through MediaStore, so the whole
  /// library is read and the matching row is picked.
  @override
  Future<Song?> scanMusicFile(String filePath) async {
    final songs = await _query();
    for (final song in songs) {
      if (song.uri == filePath) return song;
    }
    return null;
  }

  @override
  Future<List<Song>> getAllSongs() => _query();

  @override
  Future<List<Song>> searchSongs(String query) async {
    final songs = await _query();
    if (query.isEmpty) return songs;
    final needle = query.toLowerCase();
    return songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(needle) ||
              song.artist.toLowerCase().contains(needle) ||
              song.album.toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  List<String> getDefaultMusicPaths() =>
      MusicScannerConfig.getMobileMusicPaths();

  @override
  Future<List<Song>> scanCustomPaths(List<String> paths) => _query();

  Future<List<Song>> _query() async {
    try {
      final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'listAudio',
      );
      if (rows == null) return const [];
      return rows.map(_songOf).whereType<Song>().toList();
    } on PlatformException catch (error) {
      if (error.code == 'permission_denied' && !_permissionReported) {
        _permissionReported = true;
        Log.info('MediaStore: 没有媒体读取权限，跳过扫描');
        return const [];
      }
      Log.error('MediaStore 扫描失败: ${error.code} ${error.message}');
      return const [];
    } on MissingPluginException catch (error) {
      Log.error('MediaStore 通道不可用: $error');
      return const [];
    }
  }

  Song? _songOf(Map<Object?, Object?> row) {
    final uri = row['uri'] as String?;
    if (uri == null || uri.isEmpty) return null;
    final addedSeconds = row['dateAddedSeconds'] as int? ?? 0;
    final duration = row['durationMs'] as int? ?? 0;
    return Song(
      id: uri.hashCode,
      title: row['title'] as String? ?? '',
      artist: row['artist'] as String? ?? '',
      album: row['album'] as String? ?? '',
      duration: duration,
      uri: uri,
      dateAdded: addedSeconds * 1000,
      year: row['year'] as int?,
      size: row['size'] as int?,
      type: 'audio',
      externalId: '${row['mediaId']}',
    );
  }
}
