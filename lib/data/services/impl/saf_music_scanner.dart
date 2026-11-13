import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/impl/media_store_music_scanner.dart';
import 'package:tune/data/services/impl/saf_method_channel.dart';
import 'package:tune/data/services/impl/system_library_row.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';
import 'package:tune/data/services/music_scanner_config.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// The folder of the reader stopped answering: the permission was taken back
/// or the card was removed. A scan then fails instead of looking empty, so the
/// library keeps the rows it already has.
class SafTreePermissionException implements Exception {
  const SafTreePermissionException(this.message);

  final String? message;

  @override
  String toString() => 'SAF tree permission lost: $message';
}

/// Reads the folder the reader picked through the system directory picker.
///
/// A tree is one source: the audio files it gives back are the whole truth
/// about the local source, so the library judges a row it did not bring as a
/// track that is gone (the same rule MediaStore follows).
///
/// Until a folder is picked the Android scanner stays the reader: the system
/// library is the default source of a phone.
class SafMusicScanner implements CrossPlatformMusicScanner {
  SafMusicScanner({
    required SafTreeStore tree,
    MediaStoreMusicScanner? mediaStore,
    SafMethodChannel channel = const SafMethodChannel(),
  }) : _tree = tree,
       _mediaStore = mediaStore ?? MediaStoreMusicScanner(),
       _channel = channel;

  /// How many rows one native walk answers with.
  static const int pageSize = 500;

  final SafTreeStore _tree;
  final MediaStoreMusicScanner _mediaStore;
  final SafMethodChannel _channel;

  /// Logged once: a permission that was taken back fails on every scan, and
  /// the reader only needs to be told once per process.
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
    final songs = await _query(
      onPage: (count) {
        // The tree does not tell how large it is, so the progress leans on
        // the pages read: a page that came back full means more are coming.
        final estimate = count / (count + pageSize);
        onProgress(estimate > 0.9 ? 0.9 : estimate);
      },
    );
    onProgress(1);
    return songs;
  }

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

  Future<List<Song>> _query({void Function(int count)? onPage}) async {
    final tree = _tree.treeUri;
    if (tree == null) return _mediaStore.scanMusic();

    final songs = <Song>[];
    var offset = 0;
    try {
      while (true) {
        final page = await _channel.listTreePage(
          tree,
          offset: offset,
          limit: pageSize,
        );
        songs.addAll(page.map(songOfSystemRow).whereType<Song>());
        onPage?.call(songs.length);
        if (page.length < pageSize) break;
        offset += page.length;
      }
    } on PlatformException catch (error) {
      if (error.code == 'permission_lost') {
        if (!_permissionReported) {
          _permissionReported = true;
          Log.info('SAF: 目录授权已失效，请重新选择音乐库文件夹');
        }
        throw SafTreePermissionException(error.message);
      }
      Log.error('SAF 扫描失败: ${error.code} ${error.message}');
      rethrow;
    } on MissingPluginException catch (error) {
      Log.error('SAF 通道不可用: $error');
      return const [];
    }
    return songs;
  }
}
