import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// The library of a Logitech Media Server (Squeezebox).
///
/// LMS answers the Squeezebox command line over JSON-RPC at `/jsonrpc.js`: the
/// tracks of the library, or the tracks a keyword is found in. A track is a
/// file of the machine that runs the server, and the server hands it out at
/// `/music/<id>/download`, so the playable address needs no signing.
class LmsSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan reads, and the most it may read.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 100);

  /// The information a scan asks for with every track.
  ///
  /// The command answers with little more than a track id when nothing is
  /// asked for, so the fields the library shows are named here.
  static const _tags = 'tags:title,artist,album,duration,genre,year';

  final Dio _dio;

  LmsSourceAdapter({Dio? dio})
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
  String get sourceType => 'lms';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null;

  @override
  String get configurationHint => AppStrings.instance.lmsHint;

  /// The library is a list the server serves by itself, so the source is
  /// ready as it is: a keyword narrows the list instead of being required.
  @override
  List<String> get browseModes => const [BrowseMode.charts];

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.lmsFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'user',
      AppStrings.instance.fieldUser,
      AppStrings.instance.lmsFieldUserHint,
    ),
    MusicSourceField(
      'password',
      AppStrings.instance.fieldPassword,
      AppStrings.instance.lmsFieldPasswordHint,
      secret: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.lmsFieldQueryHint,
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
      final limit = scanLimit.read(config.setting('limit'));
      final query = config.setting('query')?.trim() ?? '';
      final headers = _authHeader(config);
      final tracks = await _titles(
        server,
        keyword: query,
        offset: request.offset,
        limit: limit,
        headers: headers,
      );

      final songs = <Song>[];
      for (final track in tracks) {
        final song = _songOf(
          track,
          sourceId: config.id,
          server: server,
          headers: headers,
        );
        if (song != null) songs.add(song);
      }

      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.lmsNoMatch : null,
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The tracks of one window of the library.
  ///
  /// Without a keyword the command walks the library in its own order; with
  /// one it answers the tracks the keyword is found in, which the server
  /// searches across the whole library instead of one page.
  Future<List<Map>> _titles(
    String server, {
    required String keyword,
    required int offset,
    required int limit,
    required String? headers,
  }) async {
    final command = <String>['titles', '$offset', '$limit', _tags];
    if (keyword.isNotEmpty) command.add('search:$keyword');

    final response = await _dio.post<String>(
      '$server/jsonrpc.js',
      data: jsonEncode({
        'id': 1,
        'method': 'slim.request',
        'params': ['', command],
      }),
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.jsonContentType,
        headers: headers == null ? null : {'Authorization': headers},
      ),
    );

    final result = _decode(response.data)?['result'];
    final loop = result is Map ? result['titles_loop'] : null;
    if (loop is! List) {
      throw MusicSourceFailure(AppStrings.instance.lmsEmptyResponse);
    }
    return loop.whereType<Map>().toList(growable: false);
  }

  /// One track of the library, or null when the answer names no track.
  static Song? _songOf(
    Map track, {
    required String sourceId,
    required String server,
    required String? headers,
  }) {
    final id = track['id']?.toString().trim() ?? '';
    final title = _text(track['title']);
    if (id.isEmpty || title == null) return null;

    final genre = _text(track['genre']);
    final year = SourceSongFactory.parseInt(track['year']);

    return SourceSongFactory.create(
      sourceId: sourceId,
      externalId: id,
      title: title,
      artist: _text(track['artist']) ?? '',
      album: _text(track['album']) ?? '',
      // The command answers the length in seconds, and the library keeps
      // milliseconds.
      duration: _secondsOf(track['duration']),
      streamUrl: '$server/music/$id/download',
      artworkUrl: _text(track['artwork_url']),
      genre: genre,
      year: year > 0 ? year : null,
      httpHeaders: headers == null ? null : {'Authorization': headers},
    );
  }

  /// The length of a track in milliseconds.
  ///
  /// The command answers seconds, as a number or as a string with a fraction.
  static int _secondsOf(Object? raw) {
    final seconds = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString().trim() ?? '') ?? 0;
    return seconds <= 0 ? 0 : (seconds * 1000).round();
  }

  /// The header the account of the server rides along as.
  static String? _authHeader(MusicSourceConfig config) {
    final user = config.setting('user')?.trim() ?? '';
    if (user.isEmpty) return null;
    final password = config.setting('password') ?? '';
    return 'Basic ${base64Encode(utf8.encode('$user:$password'))}';
  }

  /// The server address without a trailing slash.
  static String? normalizeServer(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    var address = value;
    while (address.endsWith('/')) {
      address = address.substring(0, address.length - 1);
    }
    return isHttpAddress(address) ? address : null;
  }

  static Map<String, dynamic>? _decode(String? body) {
    if (body == null || body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String? _text(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
