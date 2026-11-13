import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/recent_window.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// An Ampache server hosts a whole music library of its own.
///
/// Ampache speaks an API of its own rather than the Subsonic one, so a server
/// that runs it is not reached by the Subsonic adapter. The reader hands in an
/// API key; the adapter trades it for a session token on every scan, because
/// the token expires and is not part of the saved configuration.
///
/// The library is browsed instead of searched: Ampache answers the tracks it
/// played most and the tracks that were added last, and a keyword narrows the
/// list down to the titles that contain it.
class AmpacheSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(25, 100);

  /// The API version the adapter asks for.
  ///
  /// Ampache 5.2 and newer answer several versions from one endpoint, and API6
  /// is the last one the older servers speak.
  static const _apiVersion = '6.0.0';

  static const _apiPath = '/server/json.server.php';

  final Dio _dio;

  AmpacheSourceAdapter({Dio? dio})
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
  String get sourceType => 'ampache';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null &&
      config.setting('apiKey') != null;

  @override
  String get configurationHint => AppStrings.instance.ampacheHint;

  @override
  List<String> get browseModes => const [
    BrowseMode.charts,
    BrowseMode.latest,
  ];

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.ampacheFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'apiKey',
      AppStrings.instance.ampacheFieldApiKey,
      AppStrings.instance.ampacheFieldApiKeyHint,
      required: true,
      secret: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.ampacheFieldQueryHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
    MusicSourceField(
      'since',
      AppStrings.instance.recentWindowField,
      AppStrings.instance.recentWindowFieldHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.recentWindowAll),
        for (final days in RecentWindow.days)
          MusicSourceChoice(
            '$days',
            AppStrings.instance.recentWindowDays('$days'),
          ),
      ],
    ),
  ];

  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 60);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final server = normalizeServer(config.setting('server'));
    if (server == null || config.setting('apiKey') == null) {
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final token = await _handshake(server, config.setting('apiKey')!);
      if (token == null) return _authFailed(request.config.id);

      final query = config.setting('query') ?? config.setting('keywords');
      final limit = scanLimit.read(config.setting('limit'));
      final data = await _json(
        server,
        {
          'action': 'songs',
          'auth': token,
          'limit': '$limit',
          'offset': '${request.offset}',
          'sort': browseModeOf(config) == BrowseMode.charts
              ? 'total_count,DESC'
              : 'addition_time,DESC',
          if (query != null) 'cond': 'like,${_condValue(query)}',
        },
      );
      if (data == null) {
        return SourceScanResult(
          sourceId: request.config.id,
          status: SourceScanStatus.failed,
          message: AppStrings.instance.ampacheEmptyResponse,
        );
      }

      final songs = parseSongs(
        data,
        sourceId: request.config.id,
        since: RecentWindow.cutoff(config.setting('since')),
      );
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.ampacheNoMatch : null,
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
  ///
  /// Ampache hands the lyrics along with the song itself, so no second
  /// service is asked. A track without lyrics answers with null.
  @override
  Future<String?> fetchLyrics(MusicSourceConfig config, Song song) async {
    final server = normalizeServer(config.setting('server'));
    final apiKey = config.setting('apiKey');
    final id = song.externalId ?? '';
    if (server == null || apiKey == null || id.isEmpty) return null;

    try {
      final token = await _handshake(server, apiKey);
      if (token == null) return null;
      final data = await _json(server, {
        'action': 'song',
        'auth': token,
        'filter': id,
      });
      final lyrics = data?['lyrics'];
      if (lyrics is! String) return null;
      final trimmed = lyrics.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // A track without lyrics must not break the player.
      return null;
    }
  }

  /// Builds a fresh address of a track.
  ///
  /// The address Ampache hands out carries a stream token of the session it
  /// was read in, and the token expires. A new handshake is made before the
  /// address is handed back to the player.
  @override
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    final server = normalizeServer(config.setting('server'));
    final apiKey = config.setting('apiKey');
    final id = song.externalId ?? '';
    if (server == null || apiKey == null || id.isEmpty) return null;

    try {
      final token = await _handshake(server, apiKey);
      if (token == null) return null;
      final data = await _json(server, {
        'action': 'song',
        'auth': token,
        'filter': id,
      });
      final fresh = data == null
          ? null
          : _songFrom(data, song.sourceId ?? '');
      final url = fresh?.streamUrl;
      if (url == null) return null;
      return song.copyWith(streamUrl: url);
    } catch (_) {
      // The player reports the failure itself, the source only offers a try.
      return null;
    }
  }

  /// Trades the API key for the token of a session.
  ///
  /// Ampache answers the handshake with the token every other call carries.
  /// A server that refuses the key answers with an error, and no token.
  Future<String?> _handshake(String server, String apiKey) async {
    final data = await _json(server, {
      'action': 'handshake',
      'auth': apiKey,
      'version': _apiVersion,
    });
    final token = data?['auth'];
    return token is String && token.isNotEmpty ? token : null;
  }

  /// Asks the server a method and reads its JSON answer.
  ///
  /// The body is decoded here instead of by the transformer: some servers
  /// label their JSON as text, and a body that is not JSON must read as no
  /// answer rather than as a broken request.
  Future<Map<String, dynamic>?> _json(
    String server,
    Map<String, String> parameters,
  ) async {
    final response = await _dio.get<String>(
      '$server$_apiPath',
      queryParameters: parameters,
      options: Options(responseType: ResponseType.plain),
    );
    final body = response.data;
    if (body == null || body.trim().isEmpty) return null;
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  /// The failure of a server that did not accept the key.
  SourceScanResult _authFailed(String sourceId) {
    return SourceScanResult(
      sourceId: sourceId,
      status: SourceScanStatus.failed,
      message: AppStrings.instance.ampacheAuthFailed,
    );
  }

  /// The tracks of a list answer.
  ///
  /// Ampache answers a browse with the list under the plural name of the
  /// object, so the songs of a page live under `song`. A track without a
  /// playable address is skipped: a row that cannot sound is not a track.
  static List<Song> parseSongs(
    Map<String, dynamic> data, {
    required String sourceId,
    DateTime? since,
  }) {
    final raw = data['song'];
    if (raw is! List) return const [];
    final songs = <Song>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final row = Map<String, dynamic>.from(entry);
      // The server stamps a track with the moment it was added; a track older
      // than the window is left out, one without the stamp is kept.
      if (since != null) {
        final added = RecentWindow.dateTimeOf(_addedAtOf(row));
        if (added != null && added.isBefore(since)) continue;
      }
      final song = _songFrom(row, sourceId);
      if (song != null) songs.add(song);
    }
    return songs;
  }

  /// The moment the server added a track, out of its stamp in seconds.
  static Object? _addedAtOf(Map<String, dynamic> raw) {
    final seconds = SourceSongFactory.parseInt(raw['addition_time']);
    if (seconds <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toIso8601String();
  }

  /// One track of an answer, or null when it cannot be played.
  static Song? _songFrom(Map<String, dynamic> raw, String sourceId) {
    final id = _string(raw['id']);
    final title = _string(raw['title']) ?? _string(raw['name']);
    final url = SourceSongFactory.normalizeUrl(_string(raw['url']));
    if (id == null || title == null || url == null) return null;

    final genres = _names(raw['genre']) ?? _names(raw['genres']);
    final bitrate = _number(raw['stream_bitrate']) ?? _number(raw['bitrate']);
    final sampleRate = _number(raw['rate']);

    return SourceSongFactory.create(
      sourceId: sourceId,
      externalId: id,
      title: title,
      artist: _artistName(raw) ?? '',
      album: _nameOf(raw['album']) ?? '',
      duration: (_number(raw['time']) ?? 0) * 1000,
      streamUrl: url,
      artworkUrl: raw['has_art'] == false ? null : _string(raw['art']),
      genre: genres == null || genres.isEmpty ? null : genres.first,
      genres: genres,
      year: _positive(raw['year']),
      bitrate: bitrate == null ? null : (bitrate / 1000).round(),
      sampleRate: sampleRate == null ? null : (sampleRate / 1000).round(),
      trackNumber: _positive(raw['track']),
      discNumber: _positive(raw['disk']),
      size: _number(raw['size']),
      license: _string(raw['license']),
      description: _string(raw['comment']),
      performers: _names(raw['artists']),
    );
  }

  static String? _artistName(Map<String, dynamic> raw) {
    final artist = _nameOf(raw['artist']);
    if (artist != null) return artist;
    return _names(raw['artists'])?.join(', ');
  }

  /// The name of an answer that names an object by its name.
  ///
  /// Ampache nests the artist, the album and the genre as objects with an
  /// id and a name, and a few servers answer the bare name instead.
  static String? _nameOf(Object? raw) {
    if (raw is Map) return _string(raw['name']);
    return _string(raw);
  }

  /// The server address without a trailing slash.
  ///
  /// An Ampache installation may live under a subdirectory, so the address is
  /// kept as it was written and only the trailing slash is taken away.
  static String? normalizeServer(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    var address = value;
    while (address.endsWith('/')) {
      address = address.substring(0, address.length - 1);
    }
    return isHttpAddress(address) ? address : null;
  }

  /// The value of a filter of the browse.
  ///
  /// Ampache reads the filters of a request split on commas and semicolons,
  /// so a keyword that carries one of them would break the pair apart.
  static String _condValue(String query) =>
      query.replaceAll(RegExp(r'[;,]'), ' ').trim();

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

  static int? _positive(Object? raw) {
    final value = _number(raw);
    return value == null || value <= 0 ? null : value;
  }

  /// The names of a list of objects, when the answer carries them that way.
  static List<String>? _names(Object? raw) {
    if (raw is! List) return null;
    final names = <String>[];
    for (final entry in raw) {
      final name = entry is Map ? _string(entry['name']) : _string(entry);
      if (name != null && !names.contains(name)) names.add(name);
    }
    return names.isEmpty ? null : names;
  }
}
