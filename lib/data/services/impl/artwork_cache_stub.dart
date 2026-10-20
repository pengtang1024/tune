import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tune/data/services/artwork/artwork_cache.dart';
import 'package:tune/data/services/library/library_paths.dart';

/// The artwork cache of a build that has no file system.
ArtworkCache createArtworkCache(LibraryPaths paths) => BrowserArtworkCache();

/// Keeps the covers in the browser, for the build without a file system.
///
/// The web build has no music library to write into, so there is no place to
/// keep a cover between two runs. The cover is fetched every time it is
/// asked for, and the browser keeps it in its own cache.
class BrowserArtworkCache implements ArtworkCache {
  BrowserArtworkCache({Dio? client})
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

  @override
  Future<CoverImage> imageFor(String url) async {
    final response = await _client.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    return CoverImage(bytes, imageExtension(bytes));
  }

  @override
  void dispose() {
    _client.close(force: true);
  }
}
