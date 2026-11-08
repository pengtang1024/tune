import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/deezer_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Deezer answers with previews of its catalogue and serves the charts of
/// every reach itself; the tests answer the calls the way it does and look at
/// the request the adapter sends.
void main() {
  group('Deezer adapter', () {
    test('maps a song of the catalogue', () async {
      final server = _DeezerServer();
      final adapter = DeezerSourceAdapter(dio: server.dio);

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
      // The playable file is a preview, so the track lasts thirty seconds
      // even though the catalogue reports the length of the whole song.
      expect(song.duration, 30000);
      expect(song.streamUrl, contains('.mp3'));
      expect(song.artworkUrl, endsWith('/1000x1000-000000-80-0-0.jpg'));
      expect(song.externalId, '3818963601');
      expect(song.description, AppStrings.instance.deezerPreviewNote);
      expect(song.sourceData?['isPreview'], isTrue);
      expect(song.sourceData?['fullDurationMs'], 209000);
    });

    test('the charts are read without a keyword', () async {
      final server = _DeezerServer();
      final adapter = DeezerSourceAdapter(dio: server.dio);

      await adapter.scan(MusicSourceScanRequest(config: _config()));

      final request = server.requests.single;
      expect(request.uri.path, '/chart/0/tracks');
      expect(request.uri.queryParameters.containsKey('q'), isFalse);
      expect(request.uri.queryParameters['limit'], '20');
    });

    test('a reach reads the chart of that reach', () async {
      final server = _DeezerServer();
      final adapter = DeezerSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(config: _config(settings: const {'genre': 'jazz'})),
      );

      expect(server.requests.single.uri.path, '/chart/129/tracks');
    });

    test('a keyword searches the catalogue', () async {
      final server = _DeezerServer();
      final adapter = DeezerSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': '  miles davis  '}),
        ),
      );

      final request = server.requests.single;
      expect(request.uri.path, '/search');
      expect(request.uri.queryParameters['q'], 'miles davis');
    });

    test('a later window asks for the songs after the first ones', () async {
      final server = _DeezerServer();
      final adapter = DeezerSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'limit': '5'}),
          offset: 10,
        ),
      );

      final request = server.requests.single;
      expect(request.uri.queryParameters['limit'], '5');
      expect(request.uri.queryParameters['index'], '10');
    });

    test('a song without a preview is left out', () async {
      final server = _DeezerServer(
        data: [
          _songJson(),
          _songJson(preview: ''),
        ],
      );
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
    });

    test('an empty answer is reported as no match', () async {
      final server = _DeezerServer(data: const []);
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.deezerNoMatch);
    });

    test('an answer without a list is reported', () async {
      final server = _DeezerServer(broken: true);
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.deezerEmptyResponse);
    });

    test('the address of a track is renewed from the track', () async {
      final server = _DeezerServer();
      final adapter = DeezerSourceAdapter(dio: server.dio);
      final scanned = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );
      final song = scanned.songs.single;

      server.preview = 'https://cdnt-preview.example.com/other.mp3';
      final refreshed = await adapter.refreshStream(_config(), song);

      expect(refreshed, isNotNull);
      expect(refreshed!.streamUrl, 'https://cdnt-preview.example.com/other.mp3');
      expect(refreshed.dateAdded, song.dateAdded);
      expect(server.requests.last.uri.path, '/track/3818963601');
    });
  });
}

MusicSourceConfig _config({Map<String, String> settings = const {}}) {
  return MusicSourceConfig(
    id: 'deezer',
    type: 'deezer',
    name: 'Deezer',
    kind: MusicSourceKind.openCatalog,
    settings: {'query': '', 'genre': '', ...settings},
  );
}

Map<String, dynamic> _songJson({String? preview}) {
  return {
    'id': 3818963601,
    'title': 'So What',
    'duration': 209,
    'preview': preview ??
        'https://cdnt-preview.example.com/abc.mp3?hdnea=exp=1',
    'link': 'https://www.deezer.com/track/3818963601',
    'artist': {'id': 44984, 'name': 'Miles Davis'},
    'album': {
      'id': 268443092,
      'title': 'Kind of Blue',
      'cover_xl': 'https://cdn-images.example.com/cover/abc/1000x1000-000000-80-0-0.jpg',
    },
  };
}

/// A catalogue that answers the calls the adapter makes.
class _DeezerServer {
  _DeezerServer({List<Map<String, dynamic>>? data, this.broken = false})
    : data = data ?? [_songJson()];

  final List<Map<String, dynamic>> data;
  final bool broken;
  final requests = <RequestOptions>[];
  String? preview;

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (broken) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({'error': {'message': 'no data'}}),
                statusCode: 200,
              ),
            );
            return;
          }
          if (options.uri.path.startsWith('/track/')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'id': 3818963601,
                  'title': 'So What',
                  'preview': preview ?? 'https://cdnt-preview.example.com/abc.mp3',
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              data: jsonEncode({'data': data, 'total': data.length}),
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}
