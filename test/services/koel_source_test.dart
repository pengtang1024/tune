import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/koel_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Koel speaks a JSON API of its own: the account is traded for a token, the
/// token is carried by every later call, and a playable address is signed for
/// one session and read per track.
///
/// The tests below answer the calls the way a server does: a sign-in that
/// hands out a token, a track list that is paginated by fifty, a search that
/// narrows the whole library, a signed address, and a track that carries its
/// lyrics.
void main() {
  group('Koel adapter', () {
    test('a window of stamps is applied before the addresses are asked for', () async {
      final today = DateTime.now().toUtc().toIso8601String();
      final server = _KoelServer(
        tracks: [
          {..._trackJson(id: 'uuid-new'), 'title': 'New', 'created_at': today},
          {..._trackJson(id: 'uuid-old'), 'title': 'Old', 'created_at': '2019-05-04T10:00:00Z'},
        ],
      );

      final result = await KoelSourceAdapter(dio: _dio(server)).scan(
        MusicSourceScanRequest(
          config: _config(extra: const {'since': '30', 'limit': '10'}),
        ),
      );

      expect(result.songs.map((song) => song.title), ['New']);
      // The track outside the window never asked for a signed address.
      expect(server.signatures, 1);
    });
    test('maps a track of the server', () async {
      final server = _KoelServer();
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(extra: {'limit': '10'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.message, isNull);
      expect(result.songs, hasLength(1));

      final song = result.songs.single;
      expect(song.title, 'So What');
      expect(song.artist, 'Miles Davis');
      expect(song.album, 'Kind of Blue');
      expect(song.duration, 545000);
      expect(
        song.streamUrl,
        'http://music.local/api/songs/uuid-1/play?signature=sig-1',
      );
      expect(song.artworkUrl, 'http://music.local/covers/kind-of-blue.jpg');
      expect(song.genre, 'Jazz');
      expect(song.year, 1959);
      expect(song.trackNumber, 3);
      expect(song.discNumber, 1);
      expect(song.externalId, 'uuid-1');

      final login = server.requests.first;
      expect(login.method, 'POST');
      expect(login.uri.path, '/api/me');
      final body = login.data is String
          ? jsonDecode(login.data as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(login.data as Map);
      expect(body['email'], 'listener@music.local');
      expect(body['password'], 'secret');

      final list = _request(server, '/api/songs');
      expect(list.uri.queryParameters['page'], '1');
      expect(list.uri.queryParameters['sort'], 'play_count');
      expect(list.uri.queryParameters['order'], 'desc');
      expect(list.headers['Authorization'], 'Bearer token-1');
    });

    test('the latest order asks the server for the newest tracks', () async {
      final server = _KoelServer();
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(extra: {'browse': 'latest'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      final list = _request(server, '/api/songs');
      expect(list.uri.queryParameters['sort'], 'created_at');
    });

    test('a keyword searches the whole library', () async {
      final server = _KoelServer();
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(extra: {'query': '  Blue  '}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs.single.title, 'So What');

      final search = _request(server, '/api/search/songs');
      expect(search.uri.queryParameters['q'], 'Blue');
      expect(search.uri.queryParameters.containsKey('page'), isFalse);
    });

    test('a later window is read from the page that holds it', () async {
      final tracks = [
        for (var index = 0; index < 55; index++) _trackJson(id: 'uuid-$index'),
      ];
      final server = _KoelServer(tracks: tracks);
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(), offset: 52),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(3));
      expect(result.songs.first.externalId, 'uuid-52');
      expect(result.songs.last.externalId, 'uuid-54');

      final list = _request(server, '/api/songs');
      expect(list.uri.queryParameters['page'], '2');
    });

    test('a track without a signed address is not kept', () async {
      final server = _KoelServer(
        tracks: [_trackJson(id: 'uuid-1'), _trackJson(id: 'uuid-bad')],
      );
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(result.songs.single.externalId, 'uuid-1');
    });

    test('an empty library is reported as no match', () async {
      final server = _KoelServer(tracks: const []);
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.koelNoMatch);
    });

    test('a server that is not configured asks for its settings', () async {
      final server = _KoelServer();
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(configured: false)),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
      expect(result.message, AppStrings.instance.koelHint);
      expect(server.requests, isEmpty);
    });

    test('a refused account fails the scan', () async {
      final server = _KoelServer(rejectLogin: true);
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.koelAuthFailed);
    });

    test('an account with a second factor cannot sign in', () async {
      final server = _KoelServer(twoFactor: true);
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.koelTwoFactor);
    });

    test('an empty answer is reported', () async {
      final server = _KoelServer(emptyBody: true);
      final adapter = KoelSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.koelEmptyResponse);
    });

    test('the lyrics of a track are read from the track', () async {
      final server = _KoelServer();
      final adapter = KoelSourceAdapter(dio: _dio(server));
      final scanned = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );
      final song = scanned.songs.single;

      expect(await adapter.fetchLyrics(_config(), song), 'Set in the modal scale');

      server.detail['lyrics'] = '   ';
      expect(await adapter.fetchLyrics(_config(), song), isNull);
    });

    test('the address of a track is renewed with a new token', () async {
      final server = _KoelServer();
      final adapter = KoelSourceAdapter(dio: _dio(server));
      final scanned = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );
      final song = scanned.songs.single;
      expect(
        song.streamUrl,
        'http://music.local/api/songs/uuid-1/play?signature=sig-1',
      );

      server.signatures = 1;
      final refreshed = await adapter.refreshStream(_config(), song);

      expect(refreshed, isNotNull);
      expect(
        refreshed!.streamUrl,
        'http://music.local/api/songs/uuid-1/play?signature=sig-2',
      );
      expect(refreshed.dateAdded, song.dateAdded);
    });
  });
}

RequestOptions _request(_KoelServer server, String path) =>
    server.requests.firstWhere((request) => request.uri.path == path);

MusicSourceConfig _config({
  Map<String, String>? extra,
  bool configured = true,
}) {
  return MusicSourceConfig(
    id: 'koel',
    type: 'koel',
    name: 'Koel',
    kind: MusicSourceKind.openApi,
    settings: configured
        ? {
            'server': 'http://music.local',
            'email': 'listener@music.local',
            'password': 'secret',
            ...?extra,
          }
        : const {},
  );
}

Dio _dio(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

Map<String, dynamic> _trackJson({String id = 'uuid-1'}) => {
  'type': 'songs',
  'id': id,
  'title': 'So What',
  'lyrics': 'Set in the modal scale',
  'album_id': 3,
  'album_name': 'Kind of Blue',
  'artist_id': 7,
  'artist_name': 'Miles Davis',
  'album_cover': 'http://music.local/covers/kind-of-blue.jpg',
  'album_small_cover': 'http://music.local/covers/kind-of-blue-small.jpg',
  'length': 545,
  'track': 3,
  'disc': 1,
  'genre': 'Jazz',
  'year': 1959,
};

/// A server that answers the calls the adapter makes.
class _KoelServer implements HttpClientAdapter {
  _KoelServer({
    List<Map<String, dynamic>>? tracks,
    this.rejectLogin = false,
    this.twoFactor = false,
    this.emptyBody = false,
  }) : tracks = tracks ?? [_trackJson()];

  final List<Map<String, dynamic>> tracks;
  final Map<String, dynamic> detail = _trackJson();
  final List<RequestOptions> requests = [];
  bool rejectLogin;
  bool twoFactor;
  bool emptyBody;
  int signatures = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.uri.path;

    if (options.method == 'POST' && path == '/api/me') {
      if (rejectLogin) return _body('{"message": "invalid credentials"}', status: 401);
      if (twoFactor) return _body(jsonEncode({'two_factor': true}));
      return _body(
        jsonEncode({'token': 'token-1', 'audio-token': 'audio-1'}),
      );
    }

    if (emptyBody) return _body('');

    if (options.headers['Authorization'] != 'Bearer token-1') {
      return _body('{"message": "unauthenticated"}', status: 401);
    }

    if (path == '/api/search/songs') {
      final keyword = options.uri.queryParameters['q'] ?? '';
      final hits = tracks
          .where(
            (track) =>
                '${track['title']} ${track['album_name']}'.contains(keyword),
          )
          .toList();
      return _body(jsonEncode({'data': hits}));
    }

    if (path == '/api/songs') {
      final page = int.tryParse(options.uri.queryParameters['page'] ?? '1') ?? 1;
      final start = (page - 1) * 50;
      final window = tracks.skip(start).take(50).toList();
      return _body(jsonEncode({'data': window}));
    }

    if (path.endsWith('/play-url')) {
      final id = path.split('/')[3];
      if (id == 'uuid-bad') {
        return _body('{"message": "not found"}', status: 404);
      }
      signatures += 1;
      return _body(
        jsonEncode({'url': '/api/songs/$id/play?signature=sig-$signatures'}),
      );
    }

    if (path.startsWith('/api/songs/')) {
      return _body(jsonEncode(detail));
    }

    return _body('{}');
  }

  static ResponseBody _body(String text, {int status = 200}) {
    final bytes = Uint8List.fromList(utf8.encode(text));
    return ResponseBody(
      Stream<Uint8List>.value(bytes),
      status,
      headers: {
        Headers.contentLengthHeader: [bytes.length.toString()],
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
