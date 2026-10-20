import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// A Jellyfin server hosts a whole media library.
///
/// The server hands out an access token for a user and expects it on every
/// following request, so the adapter logs in once per scan and keeps the
/// token for the lifetime of that scan only.
class JellyfinSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(50, 200);

  /// The name the server shows in its logs.
  static const _clientName = 'Tune';

  /// The version the server shows in its logs.
  static const _clientVersion = '1.1.0';

  /// A stable device id, so the server keeps the session of the app.
  static const _deviceId = 'tune';

  final Dio _dio;

  JellyfinSourceAdapter({Dio? dio})
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
  String get sourceType => 'jellyfin';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null &&
      config.setting('user') != null &&
      config.setting('password') != null;

  @override
  String get configurationHint => AppStrings.instance.jellyfinHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.jellyfinFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'user',
      AppStrings.instance.fieldUser,
      AppStrings.instance.jellyfinFieldUserHint,
      required: true,
    ),
    MusicSourceField(
      'password',
      AppStrings.instance.fieldPassword,
      AppStrings.instance.jellyfinFieldPasswordHint,
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
        '$server/Items',
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
          AppStrings.instance.jellyfinEmptyResponse,
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
        '$server/Items/${Uri.encodeComponent(id)}/Lyrics',
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
        streamUrl: streamUrlFor(server, id),
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
      '$server/Users/AuthenticateByName',
      data: {'Username': user, 'Pw': password},
      options: Options(
        headers: {
          'Authorization': authorizationHeader,
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
      message: AppStrings.instance.jellyfinAuthFailed,
    );
  }

  /// The header the Jellyfin API expects on every request.
  static String get authorizationHeader =>
      'MediaBrowser Client="$_clientName", Device="$_clientName", '
      'DeviceId="$_deviceId", Version="$_clientVersion"';

  /// The server address without a trailing slash.
  ///
  /// A bare host is accepted, because the address of a self hosted server is
  /// often typed as `192.168.1.10:8096` and plain HTTP is the default there.
  static String? normalizeServer(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final withScheme = trimmed.contains('://') ? trimmed : 'http://$trimmed';
    final server = withScheme.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(server);
    if (uri == null || uri.host.isEmpty) return null;
    return server;
  }

  /// The token of an answered login.
  static String? parseToken(Map<String, dynamic>? data) {
    final token = data?['AccessToken']?.toString().trim() ?? '';
    return token.isEmpty ? null : token;
  }

  /// The lyrics of a track.
  ///
  /// Older servers answer with a single text, newer ones with a list of
  /// texts that carry their language.
  static String? parseLyrics(Map<String, dynamic>? data) {
    if (data == null) return null;

    final raw = data['Lyrics'];
    if (raw is String) {
      final text = raw.trim();
      return text.isEmpty ? null : text;
    }
    if (raw is! List) return null;

    final parts = <String>[];
    for (final item in raw) {
      final text = item is String
          ? item.trim()
          : (item is Map ? item['Text']?.toString().trim() ?? '' : '');
      if (text.isNotEmpty) parts.add(text);
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  /// The playable address of a track.
  static String streamUrlFor(String server, String itemId) =>
      '$server/Audio/${Uri.encodeComponent(itemId)}/stream?static=true';

  /// The cover of a track.
  ///
  /// The player loads the cover without the headers of the song, so the token
  /// travels in the query of the address.
  static String artworkUrlFor(String server, String itemId, {String? token}) {
    final base = '$server/Items/${Uri.encodeComponent(itemId)}/Images/Primary';
    if (token == null || token.isEmpty) return base;
    return '$base?api_key=${Uri.encodeComponent(token)}';
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseItems(
    Map<String, dynamic> data, {
    required String sourceId,
    required String server,
    String? token,
    int limit = 50,
  }) {
    final rawItems = data['Items'];
    if (rawItems is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      if (songs.length >= limit) break;

      final id = raw['Id']?.toString() ?? '';
      final title = raw['Name']?.toString().trim() ?? '';
      if (id.isEmpty || title.isEmpty || !seen.add(id)) continue;

      final media = _mediaSource(raw);
      final genres = _genresOf(raw);
      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: id,
          title: title,
          artist: _artistOf(raw),
          album: raw['Album']?.toString() ?? '',
          duration: durationFromTicks(raw['RunTimeTicks']),
          streamUrl: streamUrlFor(server, id),
          artworkUrl: artworkUrlFor(server, id, token: token),
          genre: genres?.first,
          genres: genres,
          year: _yearOf(raw),
          bitrate: _kbpsOf(raw, media),
          sampleRate: _khzOf(raw, media),
          trackNumber: _positiveInt(raw['IndexNumber']),
          discNumber: _positiveInt(raw['ParentIndexNumber']),
          size: _sizeOf(media),
          httpHeaders: token == null || token.isEmpty
              ? null
              : {'X-Emby-Token': token},
        ),
      );
    }
    return songs;
  }

  /// The file behind a track, which holds the technical details.
  static Map<dynamic, dynamic> _mediaSource(Map<dynamic, dynamic> raw) {
    final sources = raw['MediaSources'];
    if (sources is! List || sources.isEmpty) return const {};
    final first = sources.first;
    return first is Map ? first : const {};
  }

  /// The artist of a track.
  ///
  /// The album artist names the band, the list of artists names the guests,
  /// so the album artist is the better choice.
  static String _artistOf(Map<dynamic, dynamic> raw) {
    final albumArtist = raw['AlbumArtist']?.toString().trim() ?? '';
    if (albumArtist.isNotEmpty) return albumArtist;

    final artists = raw['Artists'];
    if (artists is List) {
      for (final artist in artists) {
        final name = artist?.toString().trim() ?? '';
        if (name.isNotEmpty) return name;
      }
    }
    return '';
  }

  static List<String>? _genresOf(Map<dynamic, dynamic> raw) {
    final genres = raw['Genres'];
    if (genres is! List) return null;

    final names = genres
        .map((genre) => genre?.toString().trim() ?? '')
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false);
    return names.isEmpty ? null : names;
  }

  static int? _yearOf(Map<dynamic, dynamic> raw) {
    final year = SourceSongFactory.parseInt(
      raw['Year'] ?? raw['ProductionYear'],
    );
    return year > 0 ? year : null;
  }

  /// The bitrate in kbit/s.
  ///
  /// The server counts bits per second, the library stores kilobits.
  static int? _kbpsOf(Map<dynamic, dynamic> raw, Map<dynamic, dynamic> media) {
    final bitrate = SourceSongFactory.parseInt(
      raw['Bitrate'] ?? media['Bitrate'],
    );
    return bitrate > 0 ? bitrate ~/ 1000 : null;
  }

  /// The sample rate in kHz.
  static int? _khzOf(Map<dynamic, dynamic> raw, Map<dynamic, dynamic> media) {
    final rate = SourceSongFactory.parseInt(
      raw['SampleRate'] ?? media['SampleRate'],
    );
    return rate > 0 ? rate ~/ 1000 : null;
  }

  /// The length of a track in milliseconds.
  ///
  /// The server counts time in ticks of 100 nanoseconds, so a tick is a
  /// hundredth of a millisecond.
  static int durationFromTicks(Object? raw) {
    final ticks = SourceSongFactory.parseInt(raw);
    return ticks > 0 ? ticks ~/ 10000 : 0;
  }

  static int? _positiveInt(Object? raw) {
    final value = SourceSongFactory.parseInt(raw);
    return value > 0 ? value : null;
  }

  static int? _sizeOf(Map<dynamic, dynamic> media) {
    final size = SourceSongFactory.parseInt(media['Size']);
    return size > 0 ? size : null;
  }
}
