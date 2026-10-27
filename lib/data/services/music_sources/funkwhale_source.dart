import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/media_server_items.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Funkwhale is a federated network of music libraries.
///
/// Every instance serves the tracks its owners share, and a token is only
/// needed when the instance keeps its library private. A scan reads the
/// tracks of one instance, newest first, or searches them with a keyword.
class FunkwhaleSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 50);

  final Dio _dio;

  FunkwhaleSourceAdapter({Dio? dio})
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
  String get sourceType => 'funkwhale';

  /// The instance serves its own newest tracks, so the source is ready once
  /// the address is filled in: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.latest];

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null;

  @override
  String get configurationHint => AppStrings.instance.funkwhaleHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.funkwhaleFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'token',
      AppStrings.instance.funkwhaleFieldToken,
      AppStrings.instance.funkwhaleFieldTokenHint,
      secret: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.funkwhaleFieldQueryHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  @override
  Duration get scanTimeout => const Duration(seconds: 60);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final server = normalizeServer(config.setting('server'));
    if (server == null) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final limit = scanLimit.read(config.setting('limit'));
      final keyword = config.setting('query');
      final response = await _dio.get<Map<String, dynamic>>(
        '$server/api/v1/tracks/',
        queryParameters: {
          'page_size': limit,
          'page': request.offset ~/ limit + 1,
          'ordering': '-creation_date',
          'q': ?keyword,
        },
        options: Options(headers: _authHeader(config)),
      );
      final data = response.data;
      if (data == null) {
        return failedResult(
          config.id,
          AppStrings.instance.funkwhaleEmptyResponse,
        );
      }

      final songs = parseResults(
        data,
        sourceId: config.id,
        server: server,
        token: config.setting('token'),
        limit: limit,
      );
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.funkwhaleNoMatch : null,
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The server address without a trailing slash.
  static String? normalizeServer(String? raw) =>
      MediaServerItems.trimServerAddress(raw);

  static Map<String, String>? _authHeader(MusicSourceConfig config) {
    final token = config.setting('token');
    return token == null ? null : {'Authorization': 'Bearer $token'};
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    Map<String, dynamic> data, {
    required String sourceId,
    required String server,
    String? token,
    int limit = 20,
  }) {
    final rawTracks = data['results'];
    if (rawTracks is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};
    for (final raw in rawTracks) {
      if (raw is! Map) continue;
      if (songs.length >= limit) break;

      final id = raw['id']?.toString() ?? '';
      final title = raw['title']?.toString().trim() ?? '';
      final listen = _listenUrl(raw, server);
      if (id.isEmpty || title.isEmpty || listen == null || !seen.add(id)) {
        continue;
      }

      final artist = raw['artist'];
      final album = raw['album'];
      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: id,
          title: title,
          artist: artist is Map ? artist['name']?.toString() ?? '' : '',
          album: album is Map ? album['title']?.toString() ?? '' : '',
          duration: SourceSongFactory.parseInt(raw['duration']) * 1000,
          streamUrl: listen,
          artworkUrl: _coverOf(album),
          httpHeaders: token == null || token.isEmpty
              ? null
              : {'Authorization': 'Bearer $token'},
        ),
      );
    }
    return songs;
  }

  /// The address of the audio file of a track.
  ///
  /// The instance answers with a relative listen address, and the upload of
  /// the track carries the absolute one; either is read.
  static String? _listenUrl(Map<dynamic, dynamic> raw, String server) {
    final direct = SourceSongFactory.normalizeUrl(
      raw['listen_url']?.toString(),
    );
    if (direct != null) return direct;

    final uploads = raw['uploads'];
    if (uploads is List) {
      for (final upload in uploads) {
        if (upload is! Map) continue;
        final url = SourceSongFactory.normalizeUrl(
          upload['listen_url']?.toString(),
        );
        if (url != null) return url;
      }
    }

    final relative = raw['listen_url']?.toString().trim() ?? '';
    if (relative.startsWith('/')) {
      return SourceSongFactory.normalizeUrl('$server$relative');
    }
    return null;
  }

  static String? _coverOf(Object? album) {
    if (album is! Map) return null;
    final cover = album['cover'];
    if (cover is! Map) {
      return SourceSongFactory.normalizeUrl(album['cover']?.toString());
    }
    final urls = cover['urls'];
    if (urls is! Map) {
      return SourceSongFactory.normalizeUrl(cover['url']?.toString());
    }
    for (final key in const ['large', 'medium', 'small', 'original']) {
      final url = SourceSongFactory.normalizeUrl(urls[key]?.toString());
      if (url != null) return url;
    }
    return null;
  }
}
