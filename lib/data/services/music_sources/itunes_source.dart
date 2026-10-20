import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// The iTunes search API exposes the Apple Music catalogue.
///
/// The public endpoint works without a key and without an account. Every
/// result carries a 30 second preview, which is the part Apple allows to be
/// streamed, so the source plays previews instead of full tracks.
class ITunesSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 50);

  static const _endpoint = 'https://itunes.apple.com/search';

  final Dio _dio;

  ITunesSourceAdapter({Dio? dio})
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
  String get sourceType => 'itunes';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      config.setting('query') != null;

  @override
  String get configurationHint => AppStrings.instance.itunesHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQuery,
      AppStrings.instance.itunesFieldQueryHint,
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
  Duration get scanTimeout => const Duration(seconds: 40);

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
      final limit = scanLimit.read(request.config.setting('limit'));
      final response = await _dio.get<String>(
        _endpoint,
        queryParameters: {
          'term': query,
          'media': 'music',
          'entity': 'song',
          'limit': limit,
        },
        // The API answers with `text/javascript`, so the body is decoded here
        // instead of by the transformer.
        options: Options(responseType: ResponseType.plain),
      );
      final body = response.data;
      if (body == null || body.trim().isEmpty) {
        return failedResult(request.config.id, AppStrings.instance.itunesEmptyResponse);
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return failedResult(request.config.id, AppStrings.instance.itunesEmptyResponse);
      }

      final songs = parseResults(decoded, sourceId: request.config.id);
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.itunesNoMatch : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
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

      final kind = raw['kind']?.toString();
      if (kind != null && kind != 'song') continue;

      final trackId = raw['trackId']?.toString() ?? '';
      final title = raw['trackName']?.toString().trim() ?? '';
      final streamUrl = SourceSongFactory.normalizeUrl(
        raw['previewUrl']?.toString(),
      );
      if (trackId.isEmpty ||
          title.isEmpty ||
          streamUrl == null ||
          !seen.add(trackId)) {
        continue;
      }

      final releaseDate = raw['releaseDate']?.toString() ?? '';
      final year = releaseDate.length >= 4
          ? int.tryParse(releaseDate.substring(0, 4))
          : null;

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: trackId,
          title: title,
          artist: raw['artistName']?.toString() ?? '',
          album: raw['collectionName']?.toString() ?? '',
          duration: SourceSongFactory.parseInt(raw['trackTimeMillis']),
          streamUrl: streamUrl,
          artworkUrl: _artworkUrl(raw['artworkUrl100']?.toString()),
          genre: raw['primaryGenreName']?.toString(),
          year: year,
        ),
      );
    }

    return songs;
  }

  /// Upgrades the 100 pixel thumbnail to the 600 pixel cover.
  static String? _artworkUrl(String? value) {
    final url = SourceSongFactory.normalizeUrl(value);
    if (url == null) return null;
    return url.replaceFirst(RegExp(r'\d+x\d+bb'), '600x600bb');
  }
}
