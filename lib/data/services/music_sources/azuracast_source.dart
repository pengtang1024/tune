import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/radio_source.dart';
import 'package:tune/data/services/music_sources/radio_station.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// A radio server that runs AzuraCast.
///
/// AzuraCast is a self-hosted radio front end: one server may run several
/// stations, and every station has a public listen address of its own. The
/// adapter asks the public now-playing endpoint of the server once and turns
/// every station it answers into a live track, the way the radio source does.
///
/// A server the reader runs themselves may keep its stations private. Such a
/// server refuses the endpoint without a key, so the form takes an API key;
/// a server that serves its stations publicly works without one.
class AzuracastSourceAdapter extends MusicSourceAdapter {
  /// How many stations a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 100);

  /// The public endpoint that lists the stations of a server.
  static const _apiPath = '/api/nowplaying';

  /// The header AzuraCast reads the API key from.
  static const _apiKeyHeader = 'X-API-Key';

  final Dio _dio;

  AzuracastSourceAdapter({Dio? dio})
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
  String get sourceType => 'azuracast';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null;

  @override
  String get configurationHint => AppStrings.instance.azuracastHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.azuracastFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'apiKey',
      AppStrings.instance.azuracastFieldApiKey,
      AppStrings.instance.azuracastFieldApiKeyHint,
      secret: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.radioFieldQueryHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimitStations,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

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
      final body = await _read(server, config.setting('apiKey'));
      final stations = parseStations(body);
      if (stations == null) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.failed,
          message: AppStrings.instance.azuracastEmptyResponse,
        );
      }

      final query = config.setting('query') ?? '';
      final limit = scanLimit.read(config.setting('limit'));
      final matching = stations
          .where((station) => _matches(station, query))
          .take(limit)
          .toList(growable: false);
      final songs = RadioSourceAdapter.buildSongs(
        matching,
        sourceId: config.id,
      );
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.azuracastNoMatch : null,
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.failed,
          message: AppStrings.instance.azuracastAuthFailed,
        );
      }
      return failedResult(config.id, error);
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// Asks the server for its stations and reads the body as text.
  ///
  /// The body is decoded here instead of by the transformer: a server may
  /// label its JSON as text, and a body that is not JSON must read as no
  /// answer rather than as a broken request.
  Future<String?> _read(String server, String? apiKey) async {
    final key = apiKey?.trim();
    final response = await _dio.get<String>(
      '$server$_apiPath',
      options: Options(
        responseType: ResponseType.plain,
        headers: key == null || key.isEmpty ? null : {_apiKeyHeader: key},
      ),
    );
    return response.data;
  }

  /// The stations of an answer, or null when the answer is not a list.
  ///
  /// The now-playing endpoint answers a list of stations, each with its own
  /// station object and the track on air. A station that is offline or has
  /// no playable address is skipped: a station that cannot sound is not a
  /// track.
  static List<RadioStation>? parseStations(String? body) {
    if (body == null || body.trim().isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! List) return null;

    final stations = <RadioStation>[];
    final seen = <String>{};
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final station = _stationFrom(Map<String, dynamic>.from(entry));
      if (station == null || !seen.add(station.id)) continue;
      stations.add(station);
    }
    return stations;
  }

  /// One station of an answer, or null when it cannot be played.
  static RadioStation? _stationFrom(Map<String, dynamic> entry) {
    if (entry['is_online'] == false) return null;

    final raw = entry['station'];
    final station = raw is Map
        ? Map<String, dynamic>.from(raw)
        : Map<String, dynamic>.from(entry);
    final id = _string(station['shortcode']) ?? _string(station['id']);
    final name = _string(station['name']) ?? id;
    final url = _stationUrl(station);
    if (id == null || name == null || url == null) return null;

    final song = _songOf(entry);
    final mount = _defaultMount(station);
    final listeners = _listenersOf(entry);
    return RadioStation(
      provider: 'azuracast',
      id: id,
      name: name,
      streamUrl: url,
      artworkUrl: _string(song['art']),
      genre: _string(song['genre']),
      description: _string(station['description']),
      nowPlayingArtist: _string(song['artist']),
      nowPlayingTitle: _string(song['title']),
      bitrate: _number(mount?['bitrate']) ?? _number(song['bitrate']),
      codec: _string(mount?['format'])?.toUpperCase(),
      listeners: listeners,
      homepage:
          _string(station['public_player_url']) ?? _string(station['url']),
    );
  }

  /// The track on air, when the answer carries one.
  static Map<String, dynamic> _songOf(Map<String, dynamic> entry) {
    final nowPlaying = entry['now_playing'];
    if (nowPlaying is! Map) return const {};
    final song = nowPlaying['song'];
    return song is Map ? Map<String, dynamic>.from(song) : const {};
  }

  /// The default mount of a station, or the first one it has.
  static Map<String, dynamic>? _defaultMount(Map<String, dynamic> station) {
    final mounts = station['mounts'];
    if (mounts is! List) return null;
    for (final mount in mounts) {
      if (mount is Map && mount['is_default'] == true) {
        return Map<String, dynamic>.from(mount);
      }
    }
    for (final mount in mounts) {
      if (mount is Map) return Map<String, dynamic>.from(mount);
    }
    return null;
  }

  /// The address a station is listened on.
  ///
  /// A station may name its listen address itself; a station that does not
  /// keeps it on one of its mounts.
  static String? _stationUrl(Map<String, dynamic> station) {
    final direct = SourceSongFactory.normalizeUrl(_string(station['listen_url']));
    if (direct != null) return direct;
    final defaultMount = _defaultMount(station);
    final fromDefault = SourceSongFactory.normalizeUrl(
      _string(defaultMount?['url']),
    );
    if (fromDefault != null) return fromDefault;
    final mounts = station['mounts'];
    if (mounts is! List) return null;
    for (final mount in mounts) {
      if (mount is! Map) continue;
      final url = SourceSongFactory.normalizeUrl(_string(mount['url']));
      if (url != null) return url;
    }
    return null;
  }

  static int? _listenersOf(Map<String, dynamic> entry) {
    final listeners = entry['listeners'];
    if (listeners is! Map) return null;
    return _number(listeners['current']) ?? _number(listeners['total']);
  }

  /// Whether a station matches the keyword of the source.
  ///
  /// Only the fields that belong to the station itself are searched: the
  /// track on air changes every few minutes, so matching it would make a
  /// saved keyword return a different set of stations on every scan.
  static bool _matches(RadioStation station, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    final fields = [station.name, station.description];
    return fields.any(
      (field) => field != null && field.toLowerCase().contains(needle),
    );
  }

  /// The server address without a trailing slash.
  ///
  /// An AzuraCast installation may live under a subdirectory, so the address
  /// is kept as it was written and only the trailing slash is taken away.
  static String? normalizeServer(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    var address = value;
    while (address.endsWith('/')) {
      address = address.substring(0, address.length - 1);
    }
    return isHttpAddress(address) ? address : null;
  }

  static String? _string(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _number(Object? raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }
}
