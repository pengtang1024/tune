import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Connects to a self-hosted NeteaseCloudMusicApi instance.
///
/// The adapter only talks to the base URL configured by the user; it does not
/// bundle or call any third-party service by default.
class NeteaseCloudMusicSourceAdapter extends MusicSourceAdapter {
  final Dio _dio;

  NeteaseCloudMusicSourceAdapter({Dio? dio})
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
  String get sourceId => 'netease';

  @override
  bool isConfigured(MusicSourceConfig config) => _baseUrl(config) != null;

  @override
  String get configurationHint => AppStrings.instance.neteaseHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'baseUrl',
      AppStrings.instance.neteaseFieldApi,
      'http://localhost:3000',
      required: true,
    ),
    MusicSourceField(
      'keywords',
      AppStrings.instance.neteaseFieldQuery,
      AppStrings.instance.neteaseFieldHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.neteaseFieldLimit,
      AppStrings.instance.neteaseFieldLimitHint,
      numeric: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 3);

  @override
  Duration get scanTimeout => const Duration(seconds: 60);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final baseUrl = _baseUrl(request.config);
    if (baseUrl == null) {
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final keywords =
          request.config.setting('keywords') ??
          AppStrings.instance.neteaseHotKeyword;
      final limit = (SourceSongFactory.parseInt(
        request.config.setting('limit'),
      )).clamp(1, 50);

      final searchResponse = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/search',
        queryParameters: {'keywords': keywords, 'limit': limit, 'type': 1},
      );
      final searchData = searchResponse.data;
      if (searchData == null) {
        return failedResult(sourceId, AppStrings.instance.neteaseEmptyResponse);
      }

      final candidates = parseSearchResults(searchData);
      if (candidates.isEmpty) {
        return SourceScanResult(
          sourceId: sourceId,
          status: SourceScanStatus.success,
          songs: const [],
          message: AppStrings.instance.neteaseNoMatch,
        );
      }

      final urls = await _resolveStreamUrls(
        baseUrl,
        candidates
            .map((song) => song.externalId ?? '')
            .where((id) => id.isNotEmpty),
      );

      final songs = <Song>[];
      for (final song in candidates) {
        final url = urls[song.externalId];
        if (url == null) continue;
        songs.add(song.copyWith(streamUrl: url));
      }

      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.neteaseNoStream : null,
      );
    } catch (error) {
      return failedResult(sourceId, error);
    }
  }

  /// Asks the self-hosted API for a fresh address of a track.
  ///
  /// Netease links carry a short-lived signature, so a cached link stops
  /// working a few minutes after the scan.
  @override
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    final baseUrl = _baseUrl(config);
    if (baseUrl == null) return null;

    final externalId = song.externalId ?? '';
    if (externalId.isEmpty) return null;

    final urls = await _resolveStreamUrls(baseUrl, [externalId]);
    final url = urls[externalId];
    if (url == null) return null;

    return song.copyWith(streamUrl: url);
  }

  String? _baseUrl(MusicSourceConfig config) {
    var raw = config.setting('baseUrl');
    if (raw == null) return null;
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'http://$raw';
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final text = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    return text;
  }

  Future<Map<String, String>> _resolveStreamUrls(
    String baseUrl,
    Iterable<String> ids,
  ) async {
    final idList = ids.toList(growable: false);
    if (idList.isEmpty) return const {};

    final joined = idList.join(',');
    final endpoints = [
      ('$baseUrl/song/url/v1', {'id': joined, 'level': 'standard'}),
      ('$baseUrl/song/url', {'id': joined}),
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          endpoint.$1,
          queryParameters: endpoint.$2,
        );
        final urls = _parseUrlResponse(response.data);
        if (urls.isNotEmpty) return urls;
      } catch (_) {
        // Try the legacy endpoint or report no playable URLs.
      }
    }

    return const {};
  }

  Map<String, String> _parseUrlResponse(Map<String, dynamic>? data) {
    if (data == null) return const {};

    final rawData = data['data'];
    final entries = rawData is List
        ? rawData
        : rawData is Map
        ? [rawData]
        : const [];

    final urls = <String, String>{};
    for (final entry in entries) {
      if (entry is! Map) continue;
      final id = entry['id']?.toString() ?? '';
      final url = SourceSongFactory.normalizeUrl(entry['url']?.toString());
      if (id.isNotEmpty && url != null) {
        urls[id] = url;
      }
    }
    return urls;
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseSearchResults(Map<String, dynamic> data) {
    final result = data['result'];
    final rawSongs = result is Map ? result['songs'] : data['songs'];

    if (rawSongs is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in rawSongs) {
      if (raw is! Map) continue;

      final externalId = raw['id']?.toString() ?? '';
      final title = raw['name']?.toString().trim() ?? '';
      if (externalId.isEmpty || title.isEmpty || !seen.add(externalId)) {
        continue;
      }

      final rawArtists = raw['ar'] ?? raw['artists'];
      final artist = rawArtists is List
          ? rawArtists
                .whereType<Map>()
                .map((item) => item['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .join(' / ')
          : '';

      final rawAlbum = raw['al'] ?? raw['album'];
      final albumMap = rawAlbum is Map ? rawAlbum : const <dynamic, dynamic>{};
      final album = albumMap['name']?.toString() ?? '';
      final artwork = _https(albumMap['picUrl']?.toString());

      songs.add(
        SourceSongFactory.create(
          sourceId: 'netease',
          externalId: externalId,
          title: title,
          artist: artist,
          album: album,
          duration: SourceSongFactory.parseInt(raw['dt'] ?? raw['duration']),
          artworkUrl: artwork,
        ),
      );
    }

    return songs;
  }

  static String? _https(String? value) {
    final url = SourceSongFactory.normalizeUrl(value);
    if (url == null) return null;
    return url.startsWith('http://')
        ? url.replaceFirst('http://', 'https://')
        : url;
  }
}
