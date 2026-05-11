import 'package:dio/dio.dart';
import 'package:tune/domain/models/song.dart';

class LrcSearchResult {
  final String title;
  final String artist;
  final String lrcContent;
  LrcSearchResult({required this.title, required this.artist, required this.lrcContent});
}

class LrcOnlineSearch {
  static final _dio = Dio(BaseOptions(
    headers: {'User-Agent': 'Tune/1.0.0'},
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  static Future<LrcSearchResult?> search(Song song) async {
    try {
      final response = await _dio.get(
        'https://lrclib.net/api/search',
        queryParameters: {
          'q': '${song.artist} ${song.title}',
          'track_name': song.title,
          'artist_name': song.artist,
        },
      );

      final List<dynamic> results = response.data as List<dynamic>;
      if (results.isEmpty) return null;

      final id = results[0]['id'] as int;
      return await _getLrcById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<LrcSearchResult?> _getLrcById(int id) async {
    try {
      final response = await _dio.get('https://lrclib.net/api/get/$id');
      final data = response.data as Map<String, dynamic>;
      final syncedLyrics = data['syncedLyrics'] as String?;

      if (syncedLyrics == null || syncedLyrics.isEmpty) return null;

      return LrcSearchResult(
        title: data['trackName'] as String? ?? '',
        artist: data['artistName'] as String? ?? '',
        lrcContent: syncedLyrics,
      );
    } catch (_) {
      return null;
    }
  }
}
