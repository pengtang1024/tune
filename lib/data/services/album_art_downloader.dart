import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tune/domain/models/song.dart';

class AlbumArtDownloader {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Future<String?> downloadArt(Song song) async {
    try {
      // Try Cover Art Archive: https://coverartarchive.org/release-group/{mbid}/front
      // First try Deezer API (no auth needed for search)
      final query = '${song.artist} ${song.album}';
      if (query.trim().isEmpty) return null;

      final searchResponse = await _dio.get(
        'https://api.deezer.com/search',
        queryParameters: {'q': query, 'limit': '1'},
      );

      final data = searchResponse.data as Map<String, dynamic>;
      final tracks = data['data'] as List<dynamic>?;
      if (tracks == null || tracks.isEmpty) return null;

      final album = tracks[0]['album'] as Map<String, dynamic>?;
      final coverUrl = album?['cover_xl'] as String?;
      if (coverUrl == null) return null;

      // Download and cache
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/album_art');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final fileName = '${song.artist}_${song.album}.jpg'
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${cacheDir.path}/$fileName';

      // Skip if already cached
      if (await File(filePath).exists()) return filePath;

      await _dio.download(coverUrl, filePath);
      return filePath;
    } catch (_) {
      return null;
    }
  }
}
