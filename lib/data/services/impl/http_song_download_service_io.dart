import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// Fetches remote tracks over HTTP and keeps them in the app support folder.
///
/// The file name is derived from a stable hash of the canonical song URI so
/// the same track always maps to the same file, and the audio extension is
/// taken from the stream URL so the backend can still detect the container.
class HttpSongDownloadService implements SongDownloadService {
  HttpSongDownloadService({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              followRedirects: true,
            ),
          );

  final Dio _client;
  Directory? _storeDirectory;

  @override
  bool get isSupported => true;

  @override
  Future<String?> storedFileFor(Song song) async {
    final file = await _targetFile(song);
    return await file.exists() ? file.path : null;
  }

  @override
  Future<String> download(
    Song song, {
    void Function(double progress)? onProgress,
  }) async {
    final target = await _targetFile(song);
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');

    try {
      await _client.download(
        song.playbackUri,
        partial.path,
        deleteOnError: true,
        options: Options(headers: song.httpHeaders),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received / total);
          }
        },
      );
    } catch (error, stackTrace) {
      Log.error('下载音源失败: $error\n$stackTrace');
      rethrow;
    }

    await partial.rename(target.path);
    onProgress?.call(1);
    return target.path;
  }

  @override
  void dispose() {
    _client.close(force: true);
  }

  /// Resolves the file a track is stored in.
  Future<File> _targetFile(Song song) async {
    final directory = await _store();
    final name = '${_stableKey(song.uri)}.${_extensionFor(song.playbackUri)}';
    return File(path.join(directory.path, name));
  }

  Future<Directory> _store() async {
    final cached = _storeDirectory;
    if (cached != null) {
      return cached;
    }
    final base = await getApplicationSupportDirectory();
    final directory = Directory(path.join(base.path, 'downloads'));
    await directory.create(recursive: true);
    _storeDirectory = directory;
    return directory;
  }

  /// 64 bit hash rendered as hex.
  ///
  /// The hash has to stay identical between runs, so the randomised
  /// `Object.hashCode` cannot be used. Two independent 31 bit djb2 rounds are
  /// used instead of one 64 bit FNV-1a round: every intermediate value stays
  /// below 2^53, so the web build computes the same name as the native one.
  static String _stableKey(String value) {
    var first = 5381;
    var second = 52711;
    for (final unit in value.codeUnits) {
      first = (first * 33 + unit) & 0x7fffffff;
      second = (second * 31 + unit) & 0x7fffffff;
    }
    return '${first.toRadixString(16).padLeft(8, '0')}'
        '${second.toRadixString(16).padLeft(8, '0')}';
  }

  static const _audioExtensions = {
    'aac',
    'flac',
    'm4a',
    'mp3',
    'oga',
    'ogg',
    'opus',
    'wav',
    'weba',
    'webm',
  };

  /// Picks the container of the stream URL, falling back to mp3.
  static String _extensionFor(String url) {
    final uri = Uri.tryParse(url);
    final extension = uri == null
        ? ''
        : path.extension(uri.path).replaceFirst('.', '').toLowerCase();
    return _audioExtensions.contains(extension) ? extension : 'mp3';
  }
}
