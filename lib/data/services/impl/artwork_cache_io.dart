import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/artwork/artwork_cache.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/utils/logger.dart';
import 'package:tune/utils/stable_key.dart';

/// The artwork cache of a build that has a file system.
ArtworkCache createArtworkCache(LibraryPaths paths) => FileArtworkCache(paths);

/// Keeps the covers on disk, one file per address.
///
/// The file name is derived from a stable hash of the address, so the same
/// cover is fetched once and then read from the disk after a restart. The
/// files are spread over subfolders, so a single folder never holds more
/// than a handful of pictures.
class FileArtworkCache implements ArtworkCache {
  FileArtworkCache(this._paths, {Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              followRedirects: true,
            ),
          );

  final LibraryPaths _paths;
  final Dio _client;

  /// The fetches that are running right now, keyed by the address.
  final Map<String, Future<CoverImage>> _running = {};

  @override
  Future<CoverImage> imageFor(String url) async {
    final file = await _fileFor(url);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return CoverImage(bytes, imageExtension(bytes));
    }

    // Two covers of the same address on the screen are fetched once.
    final running = _running[url];
    if (running != null) return running;

    final transfer = _fetch(url, file);
    _running[url] = transfer;
    try {
      return await transfer;
    } finally {
      _running.remove(url);
    }
  }

  Future<CoverImage> _fetch(String url, File file) async {
    final response = await _client.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    await _store(file, bytes);
    return CoverImage(bytes, imageExtension(bytes));
  }

  /// Writes the cover into the store.
  ///
  /// A cover that cannot be stored is still shown; it is fetched again the
  /// next time it is asked for.
  Future<void> _store(File file, Uint8List bytes) async {
    try {
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await file.writeAsBytes(bytes, flush: true);
    } catch (error, stackTrace) {
      Log.error('保存封面失败: ${file.path}\n$stackTrace');
    }
  }

  Future<File> _fileFor(String url) async {
    final folder = await _paths.coverCacheFolder();
    final key = stableKey(url);
    final bucket = key.substring(0, 2);
    return File(path.join(folder.path, bucket, '$key.img'));
  }

  @override
  void dispose() {
    _client.close(force: true);
  }
}
