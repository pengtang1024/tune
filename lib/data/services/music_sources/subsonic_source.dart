import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/utils/logger.dart';

/// A Subsonic server hosts a whole music library.
///
/// Navidrome, Airsonic and Gonic all speak the Subsonic API, so one adapter
/// covers every self hosted library. The API asks for a salted token, which
/// this adapter builds from the password, and it answers with JSON when the
/// `f=json` parameter is used.
class SubsonicSourceAdapter extends MusicSourceAdapter {
  static const _apiVersion = '1.16.1';
  static const _clientName = 'tune';

  final Dio _dio;

  SubsonicSourceAdapter({Dio? dio})
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
  String get sourceId => 'subsonic';

  @override
  bool isConfigured(MusicSourceConfig config) {
    return _server(config) != null &&
        config.setting('user') != null &&
        config.setting('password') != null;
  }

  @override
  String get configurationHint => AppStrings.instance.subsonicHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.subsonicFieldServer,
      AppStrings.instance.subsonicFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'user',
      AppStrings.instance.subsonicFieldUser,
      AppStrings.instance.subsonicFieldUserHint,
      required: true,
    ),
    MusicSourceField(
      'password',
      AppStrings.instance.subsonicFieldPassword,
      AppStrings.instance.subsonicFieldPasswordHint,
      required: true,
      secret: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.subsonicFieldQuery,
      AppStrings.instance.subsonicFieldQueryHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.subsonicFieldLimit,
      AppStrings.instance.subsonicFieldLimitHint,
      numeric: true,
    ),
    MusicSourceField(
      'format',
      AppStrings.instance.subsonicFieldFormat,
      AppStrings.instance.subsonicFieldFormatHint,
      choices: [
        MusicSourceChoice(
          'original',
          AppStrings.instance.subsonicFormatOriginal,
        ),
        const MusicSourceChoice('mp3', 'MP3'),
        const MusicSourceChoice('opus', 'Opus'),
        const MusicSourceChoice('flac', 'FLAC'),
      ],
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 60);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    if (!isConfigured(config)) {
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final query = config.setting('query') ?? config.setting('keywords');
      final limit = _readLimit(config);
      final response = await _dio.get<String>(
        _endpoint(config, 'search3'),
        queryParameters: {
          ..._auth(config),
          'f': 'json',
          'query': query ?? '',
          'songCount': limit,
          'artistCount': 0,
          'albumCount': 0,
        },
        // Servers answer with `application/json` or `text/plain`, so the body
        // is decoded here instead of by the transformer.
        options: Options(responseType: ResponseType.plain),
      );

      final body = response.data;
      if (body == null || body.trim().isEmpty) {
        return failedResult(
          sourceId,
          AppStrings.instance.subsonicEmptyResponse,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return failedResult(
          sourceId,
          AppStrings.instance.subsonicEmptyResponse,
        );
      }

      final payload = _payload(decoded);
      if (payload == null) {
        return failedResult(sourceId, AppStrings.instance.subsonicAuthFailed);
      }
      if (payload['status']?.toString() != 'ok') {
        return failedResult(
          sourceId,
          AppStrings.instance.subsonicError(
            payload['error']?.toString() ?? 'unknown',
          ),
        );
      }

      final songs = parseSearchResults(payload, config: config);
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.subsonicNoMatch : null,
      );
    } catch (error) {
      return failedResult(sourceId, error);
    }
  }

  /// Builds a fresh signed address for a track.
  ///
  /// The token contains a random salt, so a new address is generated on every
  /// refresh. The player calls this when a stored address stopped working.
  @override
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    if (!isConfigured(config)) return null;

    final id = song.externalId ?? '';
    if (id.isEmpty) return null;

    final suffix = song.sourceData?['suffix']?.toString() ?? 'mp3';
    final url = _streamUrl(config, id, suffix: suffix);
    if (url == null) return null;

    return song.copyWith(streamUrl: url);
  }

  /// Reads the lyrics a Subsonic server stores for a track.
  ///
  /// Servers that keep lyrics answer with the text of the track, so the
  /// player can show it next to the cover.
  @override
  Future<String?> fetchLyrics(MusicSourceConfig config, Song song) async {
    if (!isConfigured(config)) return null;
    if (song.title.trim().isEmpty) return null;

    try {
      final response = await _dio.get<String>(
        _endpoint(config, 'getLyrics'),
        queryParameters: {
          ..._auth(config),
          'f': 'json',
          'artist': song.artist,
          'title': song.title,
        },
        options: Options(responseType: ResponseType.plain),
      );

      final body = response.data;
      if (body == null || body.trim().isEmpty) return null;

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final payload = _payload(decoded);
      if (payload == null) return null;

      return parseLyrics(payload);
    } catch (error) {
      Log.error('读取 Subsonic 歌词失败: $error');
      return null;
    }
  }

  /// Reads the text of the lyrics out of a `getLyrics` answer.
  ///
  /// Kept static so the mapping can be tested without network access.
  static String? parseLyrics(Map<String, dynamic> payload) {
    final lyrics = payload['lyrics'];
    if (lyrics is! Map) return null;

    final song = lyrics['song'];
    if (song is! Map) return null;

    final value = song['value']?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  /// Reads the search answer of a Subsonic server.
  ///
  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseSearchResults(
    Map<String, dynamic> payload, {
    required MusicSourceConfig config,
    String sourceId = 'subsonic',
  }) {
    final search = payload['search3'];
    final result = search is Map ? search['result'] : null;
    final rawSongs = result is Map ? result['song'] : null;
    if (rawSongs is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in rawSongs) {
      if (raw is! Map) continue;

      final id = raw['id']?.toString() ?? '';
      final title = raw['title']?.toString().trim() ?? '';
      if (id.isEmpty || title.isEmpty || !seen.add(id)) continue;

      final suffix = raw['suffix']?.toString() ?? 'mp3';
      final streamUrl = _streamUrl(config, id, suffix: suffix);
      if (streamUrl == null) continue;

      final year = SourceSongFactory.parseInt(raw['year']);
      final trackNumber = SourceSongFactory.parseInt(raw['track']);
      final bitrate = SourceSongFactory.parseInt(raw['bitRate']);

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: id,
          title: title,
          artist: raw['artist']?.toString() ?? '',
          album: raw['album']?.toString() ?? '',
          duration: SourceSongFactory.parseInt(raw['duration']) * 1000,
          streamUrl: streamUrl,
          artworkUrl: _coverUrl(config, raw['coverArt']?.toString()),
          genre: raw['genre']?.toString(),
          year: year > 0 ? year : null,
          trackNumber: trackNumber > 0 ? trackNumber : null,
          bitrate: bitrate > 0 ? bitrate : null,
          size: SourceSongFactory.parseInt(raw['size']),
          sourceData: {'id': id, if (suffix.isNotEmpty) 'suffix': suffix},
        ),
      );
    }

    return songs;
  }

  /// Unwraps the `subsonic-response` envelope of the API.
  static Map<String, dynamic>? _payload(Map<String, dynamic> body) {
    final envelope = body['subsonic-response'];
    if (envelope is Map) return Map<String, dynamic>.from(envelope);
    return null;
  }

  /// Builds the signed address of a track.
  static String? _streamUrl(
    MusicSourceConfig config,
    String id, {
    String suffix = 'mp3',
  }) {
    final server = _server(config);
    final user = config.setting('user');
    final password = config.setting('password');
    if (server == null || user == null || password == null) return null;

    final salt = _salt();
    final token = md5.convert(utf8.encode('$password$salt')).toString();
    final format = _format(config, suffix);

    return Uri.parse('$server/rest/stream')
        .replace(
          queryParameters: {
            'id': id,
            ..._auth(config, salt: salt, token: token),
            'f': format,
          },
        )
        .toString();
  }

  /// The format the server delivers the track in.
  ///
  /// The user may ask for a smaller file, otherwise the track keeps the
  /// format it is stored in.
  static String _format(MusicSourceConfig config, String suffix) {
    final chosen = config.setting('format');
    if (chosen == 'mp3' || chosen == 'opus' || chosen == 'flac') {
      return chosen!;
    }
    return suffix.isEmpty ? 'mp3' : suffix;
  }

  /// Builds the signed address of a cover.
  static String? _coverUrl(MusicSourceConfig config, String? coverId) {
    if (coverId == null || coverId.isEmpty) return null;
    final server = _server(config);
    final user = config.setting('user');
    final password = config.setting('password');
    if (server == null || user == null || password == null) return null;

    final salt = _salt();
    final token = md5.convert(utf8.encode('$password$salt')).toString();

    return Uri.parse('$server/rest/getCoverArt')
        .replace(
          queryParameters: {
            'id': coverId,
            ..._auth(config, salt: salt, token: token),
          },
        )
        .toString();
  }

  /// The signed parameters every Subsonic request needs.
  static Map<String, String> _auth(
    MusicSourceConfig config, {
    String? salt,
    String? token,
  }) {
    final user = config.setting('user') ?? '';
    final password = config.setting('password') ?? '';
    final resolvedSalt = salt ?? _salt();
    final resolvedToken =
        token ?? md5.convert(utf8.encode('$password$resolvedSalt')).toString();

    return {
      'u': user,
      't': resolvedToken,
      's': resolvedSalt,
      'v': _apiVersion,
      'c': _clientName,
    };
  }

  static String _endpoint(MusicSourceConfig config, String method) {
    final server = _server(config) ?? '';
    return '$server/rest/$method';
  }

  /// The server address without a trailing slash.
  static String? _server(MusicSourceConfig config) {
    final raw = config.setting('server');
    if (raw == null) return null;
    final trimmed = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _salt() {
    final random = Random.secure();
    return List.generate(8, (_) => random.nextInt(36).toRadixString(36)).join();
  }

  int _readLimit(MusicSourceConfig config) {
    final parsed = SourceSongFactory.parseInt(config.setting('limit'));
    if (parsed <= 0) return 25;
    return parsed.clamp(1, 100);
  }
}
