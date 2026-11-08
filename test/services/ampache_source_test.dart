import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/ampache_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Ampache speaks an API of its own: the API key is traded for a session
/// token, and the token is carried by every later call.
///
/// The tests below answer the calls the way a server does: a handshake that
/// hands out a numbered token, a browse that lists one track, and a single
/// track that carries the address of the token it was read with.
void main() {
  group('Ampache adapter', () {
    test('maps a track of the server', () async {
      final server = _AmpacheServer();
      final adapter = AmpacheSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(
            settings: {
              'server': 'http://music.local/',
              'apiKey': 'secret',
              'limit': '10',
            },
          ),
          offset: 20,
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
      expect(song.streamUrl, 'http://music.local/play/token-1.mp3');
      expect(song.artworkUrl, 'http://music.local/art/42.jpg');
      expect(song.genre, 'Jazz');
      expect(song.genres, ['Jazz', 'Modal']);
      expect(song.year, 1959);
      expect(song.bitrate, 256);
      expect(song.sampleRate, 44);
      expect(song.trackNumber, 3);
      expect(song.discNumber, 1);
      expect(song.size, 12345678);
      expect(song.license, 'CC BY-NC-SA');
      expect(song.description, 'First take');
      expect(song.performers, ['Miles Davis', 'John Coltrane']);
      expect(song.externalId, '42');

      final handshake = server.requests.first.uri.queryParameters;
      expect(handshake['action'], 'handshake');
      expect(handshake['auth'], 'secret');
      expect(handshake['version'], '6.0.0');

      final browse = server.requests.last.uri.queryParameters;
      expect(browse['action'], 'songs');
      expect(browse['auth'], 'token-1');
      expect(browse['sort'], 'total_count,DESC');
      expect(browse['limit'], '10');
      expect(browse['offset'], '20');
      expect(browse.containsKey('cond'), isFalse);
    });

    test('a keyword narrows the page, the latest order sorts it', () async {
      final server = _AmpacheServer();
      final adapter = AmpacheSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(
            settings: {
              'server': 'http://music.local',
              'apiKey': 'secret',
              'query': 'jazz;loud',
              'browse': 'latest',
            },
          ),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      final browse = server.requests.last.uri.queryParameters;
      expect(browse['sort'], 'addition_time,DESC');
      expect(browse['cond'], 'like,jazz loud');
    });

    test('a track without a playable address is not kept', () async {
      final server = _AmpacheServer(song: _songJson()..['url'] = 'not an address');
      final adapter = AmpacheSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.ampacheNoMatch);
    });

    test('art the server disowns is left out', () async {
      final server = _AmpacheServer(song: _songJson()..['has_art'] = false);
      final adapter = AmpacheSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.songs.single.artworkUrl, isNull);
    });

    test('a server that is not configured asks for its settings', () async {
      final server = _AmpacheServer();
      final adapter = AmpacheSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(settings: const {})),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
      expect(result.message, AppStrings.instance.ampacheHint);
      expect(server.requests, isEmpty);
    });

    test('a refused key fails the scan', () async {
      final server = _AmpacheServer(rejectKey: true);
      final adapter = AmpacheSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.ampacheAuthFailed);
    });

    test('an empty answer is reported', () async {
      final server = _AmpacheServer(emptyBody: true);
      final adapter = AmpacheSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.ampacheEmptyResponse);
    });

    test('the lyrics of a track are read with the track', () async {
      final server = _AmpacheServer();
      final adapter = AmpacheSourceAdapter(dio: _dio(server));
      final scanned = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );
      final song = scanned.songs.single;

      final lyrics = await adapter.fetchLyrics(_config(), song);
      expect(lyrics, 'Set in the modal scale');

      server.song['lyrics'] = '   ';
      expect(await adapter.fetchLyrics(_config(), song), isNull);
    });

    test('the address of a track is renewed with a new token', () async {
      final server = _AmpacheServer();
      final adapter = AmpacheSourceAdapter(dio: _dio(server));
      final scanned = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );
      final song = scanned.songs.single;
      expect(song.streamUrl, 'http://music.local/play/token-1.mp3');

      final refreshed = await adapter.refreshStream(_config(), song);

      expect(refreshed, isNotNull);
      expect(refreshed!.streamUrl, 'http://music.local/play/token-2.mp3');
      expect(refreshed.dateAdded, song.dateAdded);
    });
  });
}

MusicSourceConfig _config({Map<String, String>? settings}) {
  return MusicSourceConfig(
    id: 'ampache',
    type: 'ampache',
    name: 'Ampache',
    kind: MusicSourceKind.openApi,
    settings:
        settings ??
        const {'server': 'http://music.local', 'apiKey': 'secret'},
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

Map<String, dynamic> _songJson() => {
  'id': '42',
  'title': 'So What',
  'artist': {'id': '7', 'name': 'Miles Davis'},
  'artists': [
    {'id': '7', 'name': 'Miles Davis'},
    {'id': '8', 'name': 'John Coltrane'},
  ],
  'album': {'id': '3', 'name': 'Kind of Blue'},
  'disk': 1,
  'track': 3,
  'genre': [
    {'id': '9', 'name': 'Jazz'},
    {'id': '10', 'name': 'Modal'},
  ],
  'time': 545,
  'year': 1959,
  'bitrate': 320000,
  'stream_bitrate': 256000,
  'rate': 44100,
  'url': 'http://music.local/play/token-1.mp3',
  'art': 'http://music.local/art/42.jpg',
  'has_art': true,
  'size': 12345678,
  'comment': 'First take',
  'license': 'CC BY-NC-SA',
  'lyrics': 'Set in the modal scale',
};

/// A server that answers the calls the adapter makes.
class _AmpacheServer implements HttpClientAdapter {
  _AmpacheServer({
    Map<String, dynamic>? song,
    this.rejectKey = false,
    this.emptyBody = false,
  }) : song = song ?? _songJson();

  final Map<String, dynamic> song;
  final List<RequestOptions> requests = [];
  bool rejectKey = false;
  bool emptyBody = false;
  int handshakes = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final query = options.uri.queryParameters;
    final action = query['action'];

    if (action == 'handshake') {
      if (rejectKey || query['auth'] != 'secret') {
        return _body('{"error": "invalid handshake"}', status: 401);
      }
      handshakes += 1;
      return _body(jsonEncode({'auth': 'token-$handshakes', 'api': '6.1.0'}));
    }

    if (emptyBody) return _body('');

    if (action == 'songs') {
      return _body(jsonEncode({'total_count': 1, 'song': [song]}));
    }

    if (action == 'song') {
      if (query['filter'] != '42') return _body('{}');
      return _body(
        jsonEncode({
          ...song,
          'url': "http://music.local/play/${query['auth']}.mp3",
        }),
      );
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
