import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Openverse aggregates openly licensed audio from Jamendo, Freesound,
/// Wikimedia Commons, ccMixter and other open catalogues.
///
/// The API works without a key. Anonymous requests are rate limited, so the
/// source is scanned at most once per [autoScanInterval].
class OpenverseSourceAdapter extends MusicSourceAdapter {
  final Dio _dio;

  OpenverseSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {
                'User-Agent': 'Tune/1.1 (Flutter open-source music player)',
                'Accept': 'application/json',
              },
            ),
          );

  @override
  String get sourceId => 'openverse';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      config.setting('query') != null;

  @override
  String get configurationHint => AppStrings.instance.openverseHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.openverseFieldQuery,
      AppStrings.instance.openverseFieldHint,
      required: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 35);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query');
    if (query == null) {
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.openverse.org/v1/audio/',
        queryParameters: {'q': query, 'page_size': 20},
      );
      final data = response.data;
      if (data == null) {
        return failedResult(
          sourceId,
          AppStrings.instance.openverseEmptyResponse,
        );
      }

      final songs = parseResults(data, sourceId: sourceId);
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.openverseNoMatch : null,
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
      final title = raw['title']?.toString().trim() ?? '';
      final streamUrl = SourceSongFactory.normalizeUrl(raw['url']?.toString());
      if (externalId.isEmpty ||
          title.isEmpty ||
          streamUrl == null ||
          !seen.add(externalId)) {
        continue;
      }

      final audioSet = raw['audio_set'];
      final album = audioSet is Map
          ? (audioSet['title']?.toString() ?? '')
          : (raw['provider']?.toString() ?? '');

      final rawGenres = raw['genres'];
      final genre = rawGenres is List && rawGenres.isNotEmpty
          ? rawGenres.first?.toString()
          : null;

      final thumbnail = SourceSongFactory.normalizeUrl(
        raw['thumbnail']?.toString(),
      );

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: externalId,
          title: title,
          artist: raw['creator']?.toString() ?? '',
          album: album,
          duration: SourceSongFactory.parseInt(raw['duration']),
          streamUrl: streamUrl,
          artworkUrl:
              thumbnail ??
              'https://api.openverse.org/v1/audio/$externalId/thumb/',
          genre: genre,
        ),
      );
    }

    return songs;
  }
}
