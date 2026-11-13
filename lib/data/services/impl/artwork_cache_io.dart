import 'dart:async';
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
          ) {
    // The folder is asked for right away: the media controls of the desktop
    // ask where a cover is without waiting, and they ask on every tick.
    unawaited(
      _folder.then<void>((folder) => _folderPath = folder.path).catchError((
        Object error,
      ) {
        // Reported once when a cover is asked for, not at startup.
      }),
    );
  }

  final LibraryPaths _paths;
  final Dio _client;

  /// The folder the covers are kept in.
  ///
  /// It is asked for once: the place is decided by [LibraryPaths], and a
  /// phone answers with the private folder of the app (docs/android.md).
  late final Future<Directory> _folder = _paths.coverCacheFolder();

  /// The folder the covers are kept in, once it is known.
  ///
  /// The media controls of the desktop ask for a file without waiting, so
  /// the answer is kept here after the folder is read.
  String? _folderPath;

  /// Whether the store turned out to be unusable.
  ///
  /// Shared storage is read-only on a phone, and a build that still points
  /// at a folder of the music library cannot write a single cover. The cover
  /// is still shown from memory; the store is not asked again, so the reason
  /// is written down once instead of once per cover (docs/android.md).
  bool _storeUnavailable = false;

  bool _gapReported = false;

  /// The fetches that are running right now, keyed by the address.
  final Map<String, Future<CoverImage>> _running = {};

  @override
  Future<CoverImage> imageFor(String url) async {
    final file = await _fileFor(url);
    if (file != null && await file.exists()) {
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

  Future<CoverImage> _fetch(String url, File? file) async {
    final response = await _client.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    if (file != null) await _store(file, bytes);
    return CoverImage(bytes, imageExtension(bytes));
  }

  /// Writes the cover into the store.
  ///
  /// A cover that cannot be stored is still shown from memory, and the store
  /// is left alone from then on: a read-only folder would otherwise fail for
  /// every picture of the session.
  Future<void> _store(File file, Uint8List bytes) async {
    if (_storeUnavailable) return;
    try {
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await file.writeAsBytes(bytes, flush: true);
    } catch (error) {
      _storeUnavailable = true;
      _reportGap(file.parent.path);
    }
  }

  void _reportGap([String? folder]) {
    if (_gapReported) return;
    _gapReported = true;
    final where = folder == null ? '' : ': $folder';
    Log.info('封面缓存不可写，封面只留在内存$where（docs/android.md）');
  }

  @override
  String? coverFileFor(String url) {
    final folder = _folderPath;
    if (folder == null) return null;
    final file = _fileIn(folder, url);
    return file.existsSync() ? file.path : null;
  }

  /// The file of the cover at [url], when the store can be used.
  ///
  /// The answer is nothing when the folder cannot even be asked for: the
  /// cover is then fetched and shown without touching the disk.
  Future<File?> _fileFor(String url) async {
    if (_storeUnavailable) return null;
    try {
      final folder = await _folder;
      _folderPath = folder.path;
      return _fileIn(folder.path, url);
    } catch (error) {
      _storeUnavailable = true;
      _reportGap();
      return null;
    }
  }

  File _fileIn(String folder, String url) {
    final key = stableKey(url);
    final bucket = key.substring(0, 2);
    return File(path.join(folder, bucket, '$key.img'));
  }

  @override
  void dispose() {
    _client.close(force: true);
  }
}
