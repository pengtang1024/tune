import 'package:dio/dio.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/domain/models/song.dart';

/// Reads lyrics from LRCLIB, an open database of song lyrics.
///
/// The database is the fallback for the sources that do not publish lyrics.
/// It answers with the plain text of a track and, when it knows them, with
/// the time stamped sheet that lets the player follow the line being sung.
class LrclibLyricsProvider implements LyricsProvider {
  static const _searchUrl = 'https://lrclib.net/api/search';

  /// A track of the same length is the same recording.
  static const _durationToleranceSeconds = 3;

  final Dio _dio;

  LrclibLyricsProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'Tune/1.1 (Flutter open-source music player)',
              },
            ),
          );

  @override
  Future<String?> lookup(Song song) async {
    if (song.title.trim().isEmpty) return null;

    final response = await _dio.get<List<dynamic>>(
      _searchUrl,
      queryParameters: {
        'track_name': song.title.trim(),
        if (song.artist.trim().isNotEmpty) 'artist_name': song.artist.trim(),
        if (song.album.trim().isNotEmpty) 'album_name': song.album.trim(),
      },
    );

    final data = response.data;
    if (data is! List || data.isEmpty) return null;
    return pickLyrics(data, song.durationInMillis);
  }

  /// Chooses the sheet that fits the track best.
  ///
  /// A sheet with time stamps is preferred, a recording of the same length is
  /// preferred over a different one, and the plain text is the last resort.
  static String? pickLyrics(List<dynamic> data, int durationInMillis) {
    String? plain;
    String? synced;
    String? plainOfSameLength;
    String? syncedOfSameLength;

    for (final raw in data) {
      if (raw is! Map) continue;

      final entryDuration = _durationOf(raw['duration']);
      final fits =
          durationInMillis > 0 &&
          entryDuration > 0 &&
          (entryDuration * 1000 - durationInMillis).abs() <=
              _durationToleranceSeconds * 1000;

      final syncedText = _text(raw['syncedLyrics']);
      final plainText = _text(raw['plainLyrics']);

      if (syncedText != null) {
        if (fits) {
          syncedOfSameLength ??= syncedText;
        } else {
          synced ??= syncedText;
        }
      }
      if (plainText != null) {
        if (fits) {
          plainOfSameLength ??= plainText;
        } else {
          plain ??= plainText;
        }
      }
    }

    return syncedOfSameLength ?? plainOfSameLength ?? synced ?? plain;
  }

  static double _durationOf(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
