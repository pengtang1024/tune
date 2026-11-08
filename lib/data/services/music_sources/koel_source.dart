import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/recent_window.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// A Koel server hosts a music library of its own.
///
/// Koel speaks a JSON API of its own, so a server that runs it is not reached
/// by the Subsonic or the Ampache adapter. The reader signs in with the email
/// and the password of an account: the adapter trades them for a token on
/// every scan, because the token expires and is not part of the saved
/// configuration.
///
/// The library is browsed by the tracks that were played most or added last,
/// and a keyword searches the whole library instead of narrowing one page.
/// Koel hands out no playable address with a track: the address is signed for
/// one listening session, so the adapter asks for one per track.
class KoelSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(25, 100);

  /// The page size of the Koel API.
  ///
  /// Koel paginates its track list by fifty and does not take a page size
  /// from the caller, so a later window is asked for by page and skipped
  /// inside that page.
  static const _pageSize = 50;

  final Dio _dio;

  KoelSourceAdapter({Dio? dio})
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
  String get sourceType => 'koel';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null &&
      config.setting('email') != null &&
      config.setting('password') != null;

  @override
  String get configurationHint => AppStrings.instance.koelHint;

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
      AppStrings.instance.koelFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'email',
      AppStrings.instance.fieldEmail,
      AppStrings.instance.koelFieldEmailHint,
      required: true,
    ),
    MusicSourceField(
      'password',
      AppStrings.instance.fieldPassword,
      AppStrings.instance.koelFieldPasswordHint,
      required: true,
      secret: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.koelFieldQueryHint,
    ),
    MusicSourceField(
      'since',
      AppStrings.instance.mediaServerFieldSince,
      AppStrings.instance.mediaServerFieldSinceHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.mediaServerSinceAll),
        for (final days in RecentWindow.days)
          MusicSourceChoice(
            '$days',
            AppStrings.instance.mediaServerSinceDays('$days'),
          ),
      ],
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

  /// A scan signs in, reads a page and signs one address per track, so it is
  /// given more time than a source that hands the addresses along.
  @override
  Duration get scanTimeout => const Duration(seconds: 120);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final server = normalizeServer(config.setting('server'));
    final email = config.setting('email');
    final password = config.setting('password');
    if (server == null || email == null || password == null) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final token = await _signIn(server, email, password);
      if (token == null) return _authFailed(config.id);

      final limit = scanLimit.read(config.setting('limit'));
      final query = _queryOf(config);
      final answer = await _tracks(
        server,
        token,
        offset: request.offset,
        limit: limit,
        query: query,
        charts: browseModeOf(config) == BrowseMode.charts,
      );
      if (answer == null) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.failed,
          message: AppStrings.instance.koelEmptyResponse,
        );
      }

      final songs = await _playable(
        config.id,
        server,
        token,
        answer,
        since: RecentWindow.cutoff(config.setting('since')),
      );
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.koelNoMatch : null,
      );
    } on MusicSourceFailure catch (error) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: error.message,
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) return _authFailed(config.id);
      return failedResult(config.id, error);
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// Reads the lyrics of a track from the server.
  ///
  /// Koel keeps the lyrics with the track itself, so one more read of the
  /// track answers them. A track without lyrics answers with null.
  @override
  Future<String?> fetchLyrics(MusicSourceConfig config, Song song) async {
    final server = normalizeServer(config.setting('server'));
    final email = config.setting('email');
    final password = config.setting('password');
    final id = song.externalId ?? '';
    if (server == null || email == null || password == null || id.isEmpty) {
      return null;
    }

    try {
      final token = await _signIn(server, email, password);
      if (token == null) return null;
      final answer = await _get(
        '$server/api/songs/${Uri.encodeComponent(id)}',
        token: token,
      );
      final lyrics = _string(answer?['lyrics']);
      return lyrics;
    } catch (_) {
      // A track without lyrics must not break the player.
      return null;
    }
  }

  /// Builds a fresh address of a track.
  ///
  /// An address of Koel is signed for one listening session and expires, so a
  /// new sign-in and a new address are made before the player retries.
  @override
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    final server = normalizeServer(config.setting('server'));
    final email = config.setting('email');
    final password = config.setting('password');
    final id = song.externalId ?? '';
    if (server == null || email == null || password == null || id.isEmpty) {
      return null;
    }

    try {
      final token = await _signIn(server, email, password);
      if (token == null) return null;
      final url = await _playUrl(server, token, id);
      if (url == null) return null;
      return song.copyWith(streamUrl: url);
    } catch (_) {
      // The player reports the failure itself, the source only offers a try.
      return null;
    }
  }

  /// Signs in and answers the token every other call carries.
  ///
  /// A server that refuses the email and the password answers with an error;
  /// an account that asks for a second factor answers with a challenge the
  /// adapter cannot answer, and is reported as such instead of as a wrong
  /// password.
  Future<String?> _signIn(String server, String email, String password) async {
    final answer = await _post(
      '$server/api/me',
      {'email': email, 'password': password},
    );
    if (answer == null) return null;
    if (answer['two_factor'] == true) {
      throw MusicSourceFailure(AppStrings.instance.koelTwoFactor);
    }
    return _string(answer['token']);
  }

  /// The tracks of one window of the list, or null when the answer is not a
  /// list of tracks.
  ///
  /// A keyword searches the whole library through Koel's own search endpoint,
  /// because a page of a big library rarely holds a match; without a keyword
  /// the list is read page by page.
  Future<List<Map<String, dynamic>>?> _tracks(
    String server,
    String token, {
    required int offset,
    required int limit,
    required String? query,
    required bool charts,
  }) async {
    if (query != null) {
      final answer = await _get(
        '$server/api/search/songs',
        token: token,
        parameters: {'q': query},
      );
      return _trackList(answer);
    }

    final page = offset ~/ _pageSize + 1;
    final skip = offset % _pageSize;
    final answer = await _get(
      '$server/api/songs',
      token: token,
      parameters: {
        'page': '$page',
        'sort': charts ? 'play_count' : 'created_at',
        'order': 'desc',
      },
    );
    final tracks = _trackList(answer);
    if (tracks == null) return null;
    if (skip >= tracks.length) return const [];
    return tracks.skip(skip).take(limit).toList(growable: false);
  }

  /// The tracks of an answer that carry a playable address.
  ///
  /// Koel signs one address per track, so the addresses are asked for in
  /// small batches: a big library would otherwise open one connection per
  /// track at once. A track whose address cannot be read is left out; a
  /// refused token stops the scan instead, because every other address would
  /// be refused as well.
  Future<List<Song>> _playable(
    String sourceId,
    String server,
    String token,
    List<Map<String, dynamic>> tracks, {
    DateTime? since,
  }) async {
    // The window is applied before the addresses are asked for: a track that
    // is left out does not cost a request.
    final kept = since == null
        ? tracks
        : [
            for (final track in tracks)
              if (_addedInside(track, since)) track,
          ];
    final songs = <Song>[];
    for (var start = 0; start < kept.length; start += 4) {
      final batch = kept.skip(start).take(4).toList(growable: false);
      final urls = await Future.wait(
        batch.map((track) async {
          final id = _string(track['id']);
          if (id == null) return null;
          try {
            return await _playUrl(server, token, id);
          } on DioException catch (error) {
            final status = error.response?.statusCode;
            if (status == 401 || status == 403) rethrow;
            return null;
          }
        }),
      );
      for (var index = 0; index < batch.length; index++) {
        final url = urls[index];
        if (url == null) continue;
        final song = _songFrom(batch[index], sourceId: sourceId, streamUrl: url);
        if (song != null) songs.add(song);
      }
    }
    return songs;
  }


  /// Whether the server added a track inside the window.
  ///
  /// Koel stamps a track with the moment it was added; a track without a
  /// stamp it can be read from is kept.
  static bool _addedInside(Map<String, dynamic> track, DateTime since) {
    final added = RecentWindow.dateTimeOf(track['created_at']);
    return added == null || !added.isBefore(since);
  }

  /// Reads the signed address of one track.
  Future<String?> _playUrl(String server, String token, String id) async {
    final answer = await _get(
      '$server/api/songs/${Uri.encodeComponent(id)}/play-url',
      token: token,
    );
    return _absolute(server, _string(answer?['url']));
  }

  /// One track of a list answer, or null when it cannot be played.
  static Song? _songFrom(
    Map<String, dynamic> raw, {
    required String sourceId,
    required String streamUrl,
  }) {
    final id = _string(raw['id']);
    final title = _string(raw['title']);
    if (id == null || title == null) return null;

    final length = _number(raw['length']);
    return SourceSongFactory.create(
      sourceId: sourceId,
      externalId: id,
      title: title,
      artist: _string(raw['artist_name']) ?? '',
      album: _string(raw['album_name']) ?? '',
      duration: length == null ? 0 : (length * 1000).round(),
      streamUrl: streamUrl,
      artworkUrl:
          _string(raw['album_cover']) ?? _string(raw['album_small_cover']),
      genre: _string(raw['genre']),
      year: _positive(raw['year']),
      trackNumber: _positive(raw['track']),
      discNumber: _positive(raw['disc']),
      lyrics: _string(raw['lyrics']),
    );
  }

  /// The tracks of a JSON answer, when it carries them.
  static List<Map<String, dynamic>>? _trackList(Map<String, dynamic>? answer) {
    final raw = answer?['data'];
    if (raw is! List) return null;
    final tracks = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is Map) tracks.add(Map<String, dynamic>.from(entry));
    }
    return tracks;
  }

  /// The keyword of the instance, when the reader wrote one.
  static String? _queryOf(MusicSourceConfig config) {
    final value = config.setting('query') ?? config.setting('keywords');
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// The failure of a server that did not accept the account.
  SourceScanResult _authFailed(String sourceId) {
    return SourceScanResult(
      sourceId: sourceId,
      status: SourceScanStatus.failed,
      message: AppStrings.instance.koelAuthFailed,
    );
  }

  /// Asks the server an address with the token of a session.
  ///
  /// The body is decoded here instead of by the transformer: a body that is
  /// not JSON must read as no answer rather than as a broken request.
  Future<Map<String, dynamic>?> _get(
    String url, {
    required String token,
    Map<String, String>? parameters,
  }) async {
    final response = await _dio.get<String>(
      url,
      queryParameters: parameters,
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return _decode(response.data);
  }

  /// Sends a JSON body and reads the JSON answer.
  Future<Map<String, dynamic>?> _post(
    String url,
    Map<String, String> body,
  ) async {
    final response = await _dio.post<String>(
      url,
      data: body,
      options: Options(responseType: ResponseType.plain),
    );
    return _decode(response.data);
  }

  static Map<String, dynamic>? _decode(String? body) {
    if (body == null || body.trim().isEmpty) return null;
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  /// The server address without a trailing slash.
  ///
  /// A Koel installation may live under a subdirectory, so the address is
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

  /// The address of an answer, made absolute against the server.
  ///
  /// Koel signs a relative address; the player can only ask an absolute one.
  static String? _absolute(String server, String? raw) {
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.hasScheme) return raw;
    return Uri.parse('$server/').resolveUri(uri).toString();
  }

  static String? _string(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static num? _number(Object? raw) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw.trim());
    return null;
  }

  static int? _positive(Object? raw) {
    final value = _number(raw);
    if (value == null) return null;
    final rounded = value.round();
    return rounded <= 0 ? null : rounded;
  }
}
