import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Audius is an open music network where artists publish their own tracks.
///
/// The public discovery API needs no key and returns complete recordings
/// together with the metadata a listener wants to see: artist, album, genre,
/// mood, release date, licence and the cover of the release.
class AudiusSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 50);

  /// The discovery node that answers searches and hands out stream addresses.
  static const _discoveryHost = 'https://discoveryprovider.audius.co';

  /// The public discovery API asks every caller to name itself.
  static const _appName = 'tune';

  final Dio _dio;

  AudiusSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'Tune/1.1 (Flutter open-source music player)',
              },
            ),
          );

  @override
  String get sourceType => 'audius';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      config.setting('query') != null;

  @override
  String get configurationHint => AppStrings.instance.audiusHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQuery,
      AppStrings.instance.audiusFieldQueryHint,
      required: true,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
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
        sourceId: request.config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_discoveryHost/v1/tracks/search',
        queryParameters: {'query': query, 'app_name': _appName},
      );
      final data = response.data;
      if (data == null) {
        return failedResult(request.config.id, AppStrings.instance.audiusEmptyResponse);
      }

      final limit = scanLimit.read(request.config.setting('limit'));
      final songs = parseResults(data, sourceId: request.config.id, limit: limit);
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.audiusNoMatch : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    Map<String, dynamic> data, {
    required String sourceId,
    int limit = 20,
  }) {
    final rawResults = data['data'];
    if (rawResults is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in rawResults) {
      if (raw is! Map) continue;
      if (songs.length >= limit) break;

      final externalId = raw['id']?.toString() ?? '';
      final title = raw['title']?.toString().trim() ?? '';
      if (externalId.isEmpty || title.isEmpty || !seen.add(externalId)) {
        continue;
      }

      final user = raw['user'];
      final artist = user is Map ? user['name']?.toString() ?? '' : '';
      final albumLink = raw['album_backlink'];
      final album = albumLink is Map
          ? albumLink['playlist_name']?.toString() ?? ''
          : '';

      final tags = raw['tags'];
      final genres = tags is String
          ? tags
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(growable: false)
          : const <String>[];

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: externalId,
          title: title,
          artist: artist,
          album: album,
          duration: SourceSongFactory.parseInt(raw['duration']) * 1000,
          streamUrl: streamUrlFor(externalId),
          artworkUrl: _artworkUrl(raw['artwork']),
          genre: raw['genre']?.toString(),
          genres: genres.isEmpty ? null : genres,
          year: _yearOf(raw['release_date']?.toString()),
          license: _licenseOf(raw['license']),
          description: _descriptionOf(raw),
        ),
      );
    }

    return songs;
  }

  /// The address of a track, which stays valid because it is resolved again
  /// on every request instead of carrying a signed link.
  static String streamUrlFor(String externalId) =>
      '$_discoveryHost/v1/tracks/$externalId/stream?app_name=$_appName';

  /// Picks the largest cover the payload offers.
  static String? _artworkUrl(Object? artwork) {
    if (artwork is! Map) return null;
    for (final size in ['1000x1000', '480x480', '150x150']) {
      final url = SourceSongFactory.normalizeUrl(artwork[size]?.toString());
      if (url != null) return url;
    }
    return null;
  }

  static String? _descriptionOf(Map<Object?, Object?> raw) {
    final description = raw['description']?.toString().trim() ?? '';
    return description.isEmpty ? null : description;
  }

  /// The licence of a track, when the network states one.
  static String? _licenseOf(Object? value) {
    final license = value?.toString().trim() ?? '';
    if (license.isEmpty) return null;
    if (license == 'All rights reserved') return null;
    return license;
  }

  /// Reads the year out of a release date such as `2020-06-22T07:04:10Z`.
  static int? _yearOf(String? date) {
    if (date == null || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }
}
