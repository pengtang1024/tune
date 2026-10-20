import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/artwork/artwork_cache.dart';
import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';
import 'package:tune/utils/stable_key.dart';

/// The download store of a build that has a file system.
SongDownloadService createSongDownloadService({
  required LibraryPaths paths,
  required ArtworkCache artwork,
}) => HttpSongDownloadService(paths: paths, artwork: artwork);

/// Fetches remote tracks over HTTP and keeps them in the music library.
///
/// The file name is derived from a stable hash of the canonical song URI so
/// the same track always maps to the same file, and the audio extension is
/// taken from the stream URL so the backend can still detect the container.
///
/// A track is fetched at most once at a time: a second request for a track
/// whose transfer is still running joins that transfer instead of writing the
/// same file twice.
class HttpSongDownloadService implements SongDownloadService {
  HttpSongDownloadService({
    Dio? client,
    required LibraryPaths paths,
    required ArtworkCache artwork,
  }) : _client =
           client ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 60),
               followRedirects: true,
             ),
           ),
       _paths = paths,
       _artwork = artwork;

  final Dio _client;

  /// Where the fetched track and its files are kept.
  final LibraryPaths _paths;

  /// Where the cover of the track comes from.
  final ArtworkCache _artwork;

  /// The transfers that are running right now, keyed by the cache key.
  final Map<String, _Transfer> _transfers = {};

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
  }) {
    final key = stableKey(song.uri);
    final url = song.playbackUri;

    final running = _transfers[key];
    if (running != null && running.url == url) {
      // The track is already on its way into the store, so the caller joins
      // that transfer instead of fetching the same bytes a second time.
      if (onProgress != null) running.listeners.add(onProgress);
      return running.future;
    }

    // A newer address replaces the running transfer: the bytes of the old
    // address would end up in a file nobody asked for.
    running?.cancel();

    final transfer = _Transfer(url: url);
    if (onProgress != null) transfer.listeners.add(onProgress);
    _transfers[key] = transfer;
    unawaited(_fetch(song, key, transfer));
    return transfer.future;
  }

  @override
  void cancel(Song song) {
    _transfers[stableKey(song.uri)]?.cancel();
  }

  @override
  void dispose() {
    for (final transfer in _transfers.values) {
      transfer.cancel();
    }
    _transfers.clear();
    _client.close(force: true);
  }

  /// Fetches the track and reports the result to the caller.
  Future<void> _fetch(Song song, String key, _Transfer transfer) async {
    try {
      final target = await _targetFile(song);
      await target.parent.create(recursive: true);
      final partial = File('${target.path}.part');

      try {
        await _client.download(
          song.playbackUri,
          partial.path,
          deleteOnError: true,
          cancelToken: transfer.cancelToken,
          options: Options(headers: song.httpHeaders),
          onReceiveProgress: (received, total) {
            if (total > 0) {
              transfer.report(received / total);
            }
          },
        );
      } catch (error, stackTrace) {
        if (transfer.cancelToken.isCancelled) {
          Log.info('下载音源已取消: ${song.title}');
        } else {
          Log.error('下载音源失败: $error\n$stackTrace');
        }
        rethrow;
      }

      await _replaceFile(partial, target);
      transfer.report(1);
      transfer.complete(target.path);
      unawaited(_storeCover(song));
    } catch (error, stackTrace) {
      if (!transfer.isCompleted) {
        transfer.fail(error, stackTrace);
      }
    } finally {
      if (identical(_transfers[key], transfer)) {
        _transfers.remove(key);
      }
    }
  }

  /// Puts a fetched file in place of an older copy of the same track.
  ///
  /// Windows refuses to rename onto a file that exists, so the older copy is
  /// removed first. The rename is tried without that step, because the file
  /// may be locked by a player that reads it right now.
  Future<void> _replaceFile(File partial, File target) async {
    try {
      await partial.rename(target.path);
    } catch (error) {
      if (!await target.exists()) rethrow;
      await target.delete();
      await partial.rename(target.path);
    }
  }

  /// Resolves the file a track is stored in.
  ///
  /// The file sits in the folder of the track, next to the cover and the
  /// lyrics, so the music library holds one folder per track.
  Future<File> _targetFile(Song song) async {
    final folder = await _paths.folderFor(song);
    final name = '${_paths.nameFor(song)}.${_extensionFor(song.playbackUri)}';
    return File(path.join(folder.path, name));
  }

  /// Puts the cover of the track next to the fetched file.
  ///
  /// A cover that cannot be written does not fail the download: the track is
  /// there, and the cover comes with the next run.
  Future<void> _storeCover(Song song) async {
    final url = song.artworkUrl;
    if (url == null || url.isEmpty) return;
    try {
      final image = await _artwork.imageFor(url);
      final file = await _paths.coverFileFor(song, image.extension);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(image.bytes, flush: true);
    } catch (error, stackTrace) {
      Log.error('保存封面失败: ${song.title}\n$stackTrace');
    }
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

/// A transfer that fetches one track into the store.
///
/// The transfer can have more than one caller: everyone who asked for the
/// track is told how far it got and gets the same file when it is stored.
class _Transfer {
  _Transfer({required this.url});

  /// The address the bytes are fetched from.
  final String url;

  /// Stops the transfer when the address is replaced by a newer one.
  final CancelToken cancelToken = CancelToken();

  /// Everyone who wants to know how far the transfer got.
  final List<void Function(double progress)?> listeners = [];

  final Completer<String> _completer = Completer<String>();

  /// Completes with the path of the stored file.
  Future<String> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  /// Tells every caller how far the transfer got.
  void report(double progress) {
    for (final listener in List.of(listeners)) {
      listener?.call(progress);
    }
  }

  void complete(String path) {
    if (!_completer.isCompleted) {
      _completer.complete(path);
    }
  }

  void fail(Object error, StackTrace stackTrace) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }

  /// Stops the transfer without completing it.
  ///
  /// The caller that asked for the transfer gets the cancellation as an error.
  void cancel() {
    if (!_completer.isCompleted) {
      cancelToken.cancel('the address was replaced');
      _completer.completeError(
        StateError('the transfer was cancelled'),
        StackTrace.current,
      );
    }
  }
}
