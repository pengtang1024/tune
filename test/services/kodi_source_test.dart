import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/kodi_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Kodi answers JSON-RPC and serves the files of its library over its web
/// server; the tests answer the call the way Kodi does and look at the
/// request the adapter sends.
void main() {
  group('Kodi adapter', () {
    test('maps a song of the library', () async {
      final server = _KodiServer();
      final adapter = KodiSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.message, isNull);
      expect(result.songs, hasLength(1));

      final song = result.songs.single;
      expect(song.title, 'So What');
      expect(song.artist, 'Miles Davis');
      expect(song.album, 'Kind of Blue');
      expect(song.duration, 545000);
      expect(song.genre, 'Jazz');
      expect(song.genres, ['Jazz', 'Modal']);
      expect(song.year, 1959);
      expect(song.trackNumber, 3);
      expect(song.discNumber, 1);
      expect(song.externalId, '7');
      expect(
        song.streamUrl,
        'http://kodi.local:8080/vfs/%2Fmusic%2Fkind-of-blue%2Fso-what.mp3',
      );
      expect(
        song.artworkUrl,
        'http://kodi.local:8080/image/image%3A%2F%2Falbum.jpg',
      );
      expect(
        song.httpHeaders?['Authorization'],
        'Basic ${base64Encode(utf8.encode('listener:secret'))}',
      );

      final request = server.requests.single;
      expect(request.uri.path, '/jsonrpc');
      final body = jsonDecode(request.data as String) as Map<String, dynamic>;
      expect(body['method'], 'AudioLibrary.GetRecentlyAddedSongs');
      final params = body['params'] as Map<String, dynamic>;
      expect(params['properties'], contains('file'));
      expect(params['limits'], {'start': 0, 'end': 20});
      expect(params.containsKey('filter'), isFalse);
      expect(
        request.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('listener:secret'))}',
      );
    });

    test('a keyword asks the library for its matches', () async {
      final server = _KodiServer();
      final adapter = KodiSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'jazz'}),
        ),
      );

      final body =
          jsonDecode(server.requests.single.data as String)
              as Map<String, dynamic>;
      expect(body['method'], 'AudioLibrary.GetSongs');
      final params = body['params'] as Map<String, dynamic>;
      final filter = params['filter'] as Map<String, dynamic>;
      final clauses = filter['or'] as List;
      expect(clauses.first['field'], 'title');
      expect(clauses.first['operator'], 'contains');
      expect(clauses.first['value'], 'jazz');
    });

    test('a later window asks for the songs after the first ones', () async {
      final server = _KodiServer();
      final adapter = KodiSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'limit': '5'}),
          offset: 20,
        ),
      );

      final body =
          jsonDecode(server.requests.single.data as String)
              as Map<String, dynamic>;
      final params = body['params'] as Map<String, dynamic>;
      expect(params['limits'], {'start': 20, 'end': 25});
    });

    test('an open web server is asked without an account', () async {
      final server = _KodiServer();
      final adapter = KodiSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'user': ''}),
        ),
      );

      expect(server.requests.single.headers.containsKey('Authorization'), isFalse);
      expect(result.songs.single.httpHeaders, isNull);
    });

    test('a picture that is already an address is kept', () async {
      final server = _KodiServer(thumbnail: 'https://cdn.example.com/cover.jpg');
      final adapter = KodiSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(
        result.songs.single.artworkUrl,
        'https://cdn.example.com/cover.jpg',
      );
    });

    test('an empty library is reported as no match', () async {
      final server = _KodiServer(songs: const []);
      final adapter = KodiSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.kodiNoMatch);
    });

    test('an error of the library is reported', () async {
      final server = _KodiServer(error: true);
      final adapter = KodiSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.kodiEmptyResponse);
    });

    test('an address that is not a web server asks for its settings', () async {
      final server = _KodiServer();
      final adapter = KodiSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(configured: false)),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
      expect(result.message, AppStrings.instance.kodiHint);
      expect(server.requests, isEmpty);
    });

    test('a server address with a trailing slash is read', () async {
      final server = _KodiServer();
      final adapter = KodiSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'server': 'http://kodi.local:8080/'}),
        ),
      );

      expect(
        result.songs.single.streamUrl,
        startsWith('http://kodi.local:8080/vfs/'),
      );
    });
  });
}

MusicSourceConfig _config({
  Map<String, String> settings = const {},
  bool configured = true,
}) {
  return MusicSourceConfig(
    id: 'kodi',
    type: 'kodi',
    name: 'Kodi',
    kind: MusicSourceKind.openApi,
    settings: configured
        ? {
            'server': 'http://kodi.local:8080',
            'user': 'listener',
            'password': 'secret',
            'query': '',
            ...settings,
          }
        : const {},
  );
}

Map<String, dynamic> _songJson({String? thumbnail}) {
  return {
    'songid': 7,
    'title': 'So What',
    'artist': ['Miles Davis'],
    'album': 'Kind of Blue',
    'duration': 545,
    'thumbnail': thumbnail ?? 'image://album.jpg',
    'file': '/music/kind-of-blue/so-what.mp3',
    'genre': ['Jazz', 'Modal'],
    'year': 1959,
    'track': 3,
    'disc': 1,
  };
}

/// A Kodi web server that answers the call the adapter makes.
class _KodiServer {
  _KodiServer({List<Map<String, dynamic>>? songs, String? thumbnail, this.error = false})
    : songs = songs ?? [_songJson(thumbnail: thumbnail)];

  final List<Map<String, dynamic>> songs;
  final bool error;
  final requests = <RequestOptions>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (error) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'jsonrpc': '2.0',
                  'id': 1,
                  'error': {'code': -32601, 'message': 'Method not found'},
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              data: jsonEncode({
                'jsonrpc': '2.0',
                'id': 1,
                'result': {'limits': {'total': songs.length}, 'songs': songs},
              }),
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}
