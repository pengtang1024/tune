import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/music_sources/source_request_headers.dart';
import 'package:tune/domain/models/song.dart';

/// Reads lyrics from LRCLIB, an open database of song lyrics.
///
/// The database is the fallback for the sources that do not publish lyrics.
/// It answers with the plain text of a track and, when it knows them, with
/// the time stamped sheet that lets the player follow the line being sung.
class LrclibLyricsProvider implements LyricsProvider {
  /// The one recording that matches the track in every way.
  static const _getUrl = 'https://lrclib.net/api/get';

  /// The recordings that may match the track.
  static const _searchUrl = 'https://lrclib.net/api/search';

  /// A track of the same length is the same recording.
  static const _durationToleranceSeconds = 3;

  /// The share of the length a recording may differ by.
  ///
  /// Another master of the same song is a few seconds longer or shorter, so
  /// the length of a long track is a loose measure.
  static const _durationToleranceShare = 0.02;

  final Dio _dio;

  LrclibLyricsProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: sourceRequestHeaders(
                extra: const {'Accept': 'application/json'},
              ),
            ),
          );

  @override
  Future<String?> lookup(Song song) async {
    final title = song.title.trim();
    if (title.isEmpty) return null;

    final artist = song.artist.trim();
    final album = song.album.trim();
    final duration = song.durationInMillis;

    final exact = await _exactMatch(
      title: title,
      artist: artist,
      album: album,
      duration: duration,
    );
    if (exact != null) return exact;

    final searched = await _search(
      title: title,
      artist: artist,
      album: album,
      duration: duration,
    );
    if (searched != null) return searched;

    // The name of the artist may carry the names of the guests, and the
    // database files the track under the name of the artist alone.
    final shortened = shortenArtist(artist);
    if (shortened.isEmpty || shortened == artist) return null;

    return _search(
      title: title,
      artist: shortened,
      album: album,
      duration: duration,
    );
  }

  /// The sheet of the recording that matches the track in every way.
  Future<String?> _exactMatch({
    required String title,
    required String artist,
    required String album,
    required int duration,
  }) async {
    if (artist.isEmpty || duration <= 0) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _getUrl,
        queryParameters: {
          'track_name': title,
          'artist_name': artist,
          if (album.isNotEmpty) 'album_name': album,
          'duration': duration ~/ 1000,
        },
      );
      return _sheetOf(response.data);
    } catch (error) {
      // The exact match is a try: the search below knows more.
      return null;
    }
  }

  /// The sheet of the recordings that may match the track.
  Future<String?> _search({
    required String title,
    required String artist,
    required String album,
    required int duration,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      _searchUrl,
      queryParameters: {
        'track_name': title,
        if (artist.isNotEmpty) 'artist_name': artist,
        if (album.isNotEmpty) 'album_name': album,
      },
    );

    final data = response.data;
    if (data is! List || data.isEmpty) return null;
    return pickLyrics(data, duration);
  }

  /// The name of the artist without the names of the guests.
  ///
  /// The name of a guest and the words that mark another master of the song
  /// are cut off, because the database files the track under the plain name.
  static String shortenArtist(String artist) {
    var name = artist.trim();
    name = name.replaceAll(_guestPattern, '');
    name = name.replaceAll(_parenthesisPattern, '');
    name = name.replaceAll(_dashPattern, '');
    return name.trim();
  }

  static final _guestPattern = RegExp(
    r'\s*\b(feat|ft|featuring)\b\.?.*$',
    caseSensitive: false,
  );

  static final _parenthesisPattern = RegExp(r'\s*[\(\[][^)\]]*[\)\]]\s*$');

  static final _dashPattern = RegExp(r'\s+[-–—]\s+.*$');

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
      final fits = _fitsDuration(entryDuration, durationInMillis);

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

  /// Whether a recording of [entrySeconds] is the track of [durationInMillis].
  static bool _fitsDuration(double entrySeconds, int durationInMillis) {
    if (durationInMillis <= 0 || entrySeconds <= 0) return false;

    final seconds = durationInMillis / 1000;
    final difference = (entrySeconds - seconds).abs();
    final tolerance = math.max(
      _durationToleranceSeconds,
      seconds * _durationToleranceShare,
    );
    return difference <= tolerance;
  }

  /// The sheet of one recording.
  static String? _sheetOf(Object? value) {
    if (value is! Map) return null;
    final synced = _text(value['syncedLyrics']);
    if (synced != null) return synced;
    return _text(value['plainLyrics']);
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
