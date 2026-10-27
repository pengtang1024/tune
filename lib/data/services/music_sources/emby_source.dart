import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/media_server_items.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// An Emby server hosts a whole media library.
///
/// Emby describes a track the way Jellyfin does and puts its own prefix in
/// front of every address, so the adapter walks the same requests one level
/// deeper than the Jellyfin one.
class EmbySourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(50, 200);

  /// The prefix every address of an Emby server carries.
  static const _prefix = '/emby';

  final Dio _dio;

  EmbySourceAdapter({Dio? dio})
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
  String get sourceType => 'emby';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null &&
      config.setting('user') != null &&
      config.setting('password') != null;

  @override
  String get configurationHint => AppStrings.instance.embyHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.embyFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'user',
      AppStrings.instance.fieldUser,
      AppStrings.instance.embyFieldUserHint,
      required: true,
    ),
    MusicSourceField(
      'password',
      AppStrings.instance.fieldPassword,
      AppStrings.instance.embyFieldPasswordHint,
      required: true,
      secret: true,
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
  Duration get scanTimeout => const Duration(seconds: 90);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final server = normalizeServer(config.setting('server'));
    if (server == null ||
        config.setting('user') == null ||
        config.setting('password') == null) {
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final token = await _authenticate(config);
      if (token == null) return _authFailed(request.config.id);

      final limit = scanLimit.read(config.setting('limit'));
      final response = await _dio.get<Map<String, dynamic>>(
        '$server/emby/Items',
        queryParameters: {
          'Recursive': 'true',
          'IncludeItemTypes': 'Audio',
          'Fields': 'Genres,MediaSources,Bitrate,SampleRate',
          'Limit': limit,
        },
        options: Options(headers: {'X-Emby-Token': token}),
      );
      final data = response.data;
      if (data == null) {
        return failedResult(
          request.config.id,
          AppStrings.instance.embyEmptyResponse,
        );
      }

      final songs = parseItems(
        data,
        sourceId: request.config.id,
        server: server,
        token: token,
        limit: limit,
      );
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.subsonicNoMatch : null,
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) return _authFailed(request.config.id);
      return failedResult(request.config.id, error);
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// Reads the lyrics of a track from the server.
  @override
  Future<String?> fetchLyrics(MusicSourceConfig config, Song song) async {
    final server = normalizeServer(config.setting('server'));
    final id = song.externalId ?? '';
    if (server == null || id.isEmpty) return null;

    try {
      final token = await _authenticate(config);
      if (token == null) return null;
      final response = await _dio.get<Map<String, dynamic>>(
        '$server/emby/Items/${Uri.encodeComponent(id)}/Lyrics',
        options: Options(headers: {'X-Emby-Token': token}),
      );
      return parseLyrics(response.data);
    } catch (_) {
      // A track without lyrics must not break the player.
      return null;
    }
  }

  /// Builds a fresh address of a track.
  ///
  /// The token of the server can be revoked, so a new one is fetched before
  /// the address is handed back to the player.
  @override
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    final server = normalizeServer(config.setting('server'));
    final id = song.externalId ?? '';
    if (server == null || id.isEmpty) return null;

    try {
      final token = await _authenticate(config);
      if (token == null) return null;
      return song.copyWith(
        streamUrl: MediaServerItems.streamUrlFor(server, _prefix, id),
        httpHeaders: {'X-Emby-Token': token},
      );
    } catch (_) {
      // The player reports the failure itself, the source only offers a try.
      return null;
    }
  }

  /// Logs the user in and returns the token of the session.
  Future<String?> _authenticate(MusicSourceConfig config) async {
    final server = normalizeServer(config.setting('server'));
    final user = config.setting('user');
    final password = config.setting('password');
    if (server == null || user == null || password == null) return null;

    final response = await _dio.post<Map<String, dynamic>>(
      '$server/emby/Users/AuthenticateByName',
      data: {'Username': user, 'Pw': password},
      options: Options(
        headers: {
          'X-Emby-Authorization': authorizationHeader,
          'Content-Type': 'application/json',
        },
      ),
    );
    return parseToken(response.data);
  }

  /// The failure of a server that did not accept the credentials.
  SourceScanResult _authFailed(String sourceId) {
    return SourceScanResult(
      sourceId: sourceId,
      status: SourceScanStatus.failed,
      message: AppStrings.instance.embyAuthFailed,
    );
  }

  /// The header the Emby API expects on a login.
  static String get authorizationHeader => MediaServerItems.authorizationHeader;

  /// The server address without a trailing slash or a trailing prefix.
  ///
  /// A bare host is accepted, and an address that already carries the
  /// prefix of the server keeps it out of the way: the adapter adds the
  /// prefix itself, so an address written with it must not turn into
  /// `emby/emby`.
  static String? normalizeServer(String? raw) {
    final server = MediaServerItems.trimServerAddress(raw);
    if (server == null) return null;
    return server.replaceFirst(RegExp(r'/emby/?$', caseSensitive: false), '');
  }

  /// The token of an answered login.
  static String? parseToken(Map<String, dynamic>? data) =>
      MediaServerItems.parseToken(data);

  /// The lyrics of a track.
  static String? parseLyrics(Map<String, dynamic>? data) =>
      MediaServerItems.parseLyrics(data);

  /// The playable address of a track.
  static String streamUrlFor(String server, String itemId) =>
      MediaServerItems.streamUrlFor(server, _prefix, itemId);

  /// The cover of a track.
  static String artworkUrlFor(String server, String itemId, {String? token}) =>
      MediaServerItems.artworkUrlFor(server, _prefix, itemId, token: token);

  /// The length of a track in milliseconds.
  static int durationFromTicks(Object? raw) =>
      MediaServerItems.durationFromTicks(raw);

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseItems(
    Map<String, dynamic> data, {
    required String sourceId,
    required String server,
    String? token,
    int limit = 50,
  }) {
    return MediaServerItems.parseItems(
      data,
      sourceId: sourceId,
      server: server,
      prefix: _prefix,
      token: token,
      limit: limit,
    );
  }
}
