import 'package:dio/dio.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Jamendo is an open catalogue of independent music.
///
/// It requires a free Client ID from https://developer.jamendo.com/, so the
/// source stays disabled until the user configures one.
class JamendoSourceAdapter extends MusicSourceAdapter {
  final Dio _dio;

  JamendoSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          );

  @override
  String get sourceId => 'jamendo';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      config.setting('clientId') != null;

  @override
  String get configurationHint => AppStrings.instance.jamendoHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'clientId',
      AppStrings.instance.jamendoFieldClientId,
      AppStrings.instance.jamendoFieldClientIdHint,
      required: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.jamendoFieldQuery,
      AppStrings.instance.jamendoFieldQueryHint,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 35);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final clientId = request.config.setting('clientId');
    if (clientId == null) {
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final query = request.config.setting('query');
      final parameters = <String, dynamic>{
        'client_id': clientId,
        'format': 'json',
        'limit': 20,
        'order': 'popularity_total',
        'include': 'musicinfo',
        'audioformat': 'mp32',
      };
      if (query != null) {
        parameters['search'] = query;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.jamendo.com/v3.0/tracks/',
        queryParameters: parameters,
      );
      final data = response.data;
      if (data == null) {
        return failedResult(sourceId, AppStrings.instance.jamendoEmptyResponse);
      }

      final songs = parseResults(data, sourceId: sourceId);
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.jamendoNoMatch : null,
      );
    } catch (error) {
      return failedResult(sourceId, error);
    }
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    Map<String, dynamic> data, {
    required String sourceId,
  }) {
    final rawResults = data['results'];
    if (rawResults is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in rawResults) {
      if (raw is! Map) continue;

      final externalId = raw['id']?.toString() ?? '';
      final title = raw['name']?.toString().trim() ?? '';
      final streamUrl = SourceSongFactory.normalizeUrl(
        (raw['audio'] ?? raw['audiodownload'])?.toString(),
      );
      if (externalId.isEmpty ||
          title.isEmpty ||
          streamUrl == null ||
          !seen.add(externalId)) {
        continue;
      }

      final musicInfo = raw['musicinfo'];
      String? genre;
      if (musicInfo is Map) {
        final tags = musicInfo['tags'];
        if (tags is Map) {
          final genres = tags['genres'];
          if (genres is List && genres.isNotEmpty) {
            genre = genres.first?.toString();
          }
        }
      }

      final releaseDate = raw['releasedate']?.toString() ?? '';
      final year = releaseDate.length >= 4
          ? int.tryParse(releaseDate.substring(0, 4))
          : null;

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: externalId,
          title: title,
          artist: raw['artist_name']?.toString() ?? '',
          album: raw['album_name']?.toString() ?? '',
          duration: SourceSongFactory.parseInt(raw['duration']) * 1000,
          streamUrl: streamUrl,
          artworkUrl: raw['image']?.toString(),
          genre: genre,
          year: year,
        ),
      );
    }

    return songs;
  }
}
