import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/json_api_source.dart';
import 'package:tune/data/services/music_sources/json_source_mapping.dart';
import 'package:tune/data/services/music_sources/json_values.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';

import 'fake_http_adapter.dart';

/// The reader points the app at an interface of their own.
///
/// The reader writes where the interface lives and where each value sits in
/// the answer; the app asks, reads and maps. Nothing the reader wrote is
/// ever run.
void main() {
  group('the path of a value', () {
    test('the steps are taken one after the other', () {
      final answer = {
        'data': {
          'songs': [
            {'title': 'Night Drive'},
          ],
        },
      };

      expect(readJsonPath(answer, 'data.songs.0.title'), 'Night Drive');
    });

    test('a step that is not there is an empty value', () {
      final answer = {
        'data': {'songs': <Object>[]},
      };

      expect(readJsonPath(answer, 'data.songs.title'), isNull);
      expect(readJsonPath(answer, 'data.songs.3'), isNull);
      expect(readJsonPath(answer, 'data.songs.x'), isNull);
    });

    test('an empty path is the whole answer', () {
      expect(readJsonPath({'a': 1}, ''), {'a': 1});
    });
  });

  group('the mapping of an answer', () {
    test('every entry of the list becomes a track', () {
      const mapping = JsonSourceMapping(
        listPath: 'data.songs',
        idPath: 'id',
        titlePath: 'title',
        artistPath: 'artist',
        urlPath: 'url',
      );

      final songs = mapping.songs(
        {
          'data': {
            'songs': [
              {
                'id': '1',
                'title': 'Night Drive',
                'artist': 'Nova',
                'url': 'https://example.com/1.mp3',
              },
              {
                'id': '2',
                'title': 'Second',
                'artist': 'Nova',
                'url': 'https://example.com/2.mp3',
              },
            ],
          },
        },
        sourceId: 'json_api-1',
      );

      expect(songs.map((song) => song.title), ['Night Drive', 'Second']);
      expect(songs.first.artist, 'Nova');
      expect(songs.first.streamUrl, 'https://example.com/1.mp3');
      expect(songs.first.sourceId, 'json_api-1');
    });

    test('a track without an address is left out', () {
      const mapping = JsonSourceMapping(
        listPath: 'songs',
        titlePath: 'title',
        urlPath: 'url',
      );

      final songs = mapping.songs(
        {
          'songs': [
            {'title': 'Night Drive', 'url': 'https://example.com/1.mp3'},
            {'title': 'Second'},
          ],
        },
        sourceId: 'json_api-1',
      );

      expect(songs.map((song) => song.title), ['Night Drive']);
    });

    test('the id falls back to the place in the list', () {
      const mapping = JsonSourceMapping(
        listPath: 'songs',
        titlePath: 'title',
        urlPath: 'url',
      );

      final songs = mapping.songs(
        {
          'songs': [
            {'title': 'Night Drive', 'url': 'https://example.com/1.mp3'},
          ],
        },
        sourceId: 'json_api-1',
      );

      expect(songs.single.externalId, '0');
    });

    test('the address may come from a template', () {
      const mapping = JsonSourceMapping(
        listPath: 'songs',
        idPath: 'id',
        titlePath: 'title',
        urlTemplate: 'https://example.com/track/\${id}.mp3',
      );

      final songs = mapping.songs(
        {
          'songs': [
            {'id': '42', 'title': 'Night Drive'},
          ],
        },
        sourceId: 'json_api-1',
      );

      expect(songs.single.streamUrl, 'https://example.com/track/42.mp3');
    });

    test('the duration is read in seconds', () {
      const mapping = JsonSourceMapping(
        listPath: 'songs',
        titlePath: 'title',
        urlPath: 'url',
        durationPath: 'length',
      );

      final songs = mapping.songs(
        {
          'songs': [
            {'title': 'Night Drive', 'url': 'https://example.com/1.mp3', 'length': 245},
            {'title': 'Second', 'url': 'https://example.com/2.mp3', 'length': '3:45'},
          ],
        },
        sourceId: 'json_api-1',
      );

      expect(songs.map((song) => song.duration), [245, 225]);
    });

    test('an answer without the list has no tracks', () {
      const mapping = JsonSourceMapping(listPath: 'data.songs');

      expect(
        mapping.songs({'data': <Object>{}}, sourceId: 'json_api-1'),
        isEmpty,
      );
    });
  });

  group('the scan of an interface', () {
    MusicSourceConfig config(Map<String, String> settings) {
      return MusicSourceConfig(
        id: 'json_api-1',
        type: 'json_api',
        name: 'JSON',
        kind: MusicSourceKind.custom,
        settings: settings,
      );
    }

    Dio dioOf(FakeHttpAdapter adapter) {
      return Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter;
    }

    test('the keyword goes into the address', () async {
      final adapter = FakeHttpAdapter()
        ..body = jsonEncode({
          'data': {
            'songs': [
              {
                'id': '1',
                'title': 'Night Drive',
                'url': 'https://example.com/1.mp3',
              },
            ],
          },
        });

      final result = await JsonApiSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/search?q=\${query}',
            'query': 'night drive',
            'listPath': 'data.songs',
            'idPath': 'id',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.songs.single.title, 'Night Drive');
      expect(
        adapter.requestedUrls.single,
        'https://example.com/search?q=night%20drive',
      );
    });

    test('the headers are sent as they are written', () async {
      final adapter = FakeHttpAdapter()..body = jsonEncode({'songs': []});

      await JsonApiSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/search',
            'headers': '{"Authorization":"Bearer x"}',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer x',
      );
    });

    test('a body is sent as a request of its own', () async {
      final adapter = FakeHttpAdapter()..body = jsonEncode({'songs': []});

      await JsonApiSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/search',
            'method': 'POST',
            'body': '{"q":"\${query}"}',
            'query': 'night drive',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.data, {'q': 'night drive'});
    });

    test('the method the reader picked is the method that goes out', () async {
      final adapter = FakeHttpAdapter()..body = jsonEncode({'songs': []});

      await JsonApiSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/search',
            'method': 'POST',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      expect(adapter.requests.single.method, 'POST');
    });

    test('a GET carries no body', () async {
      final adapter = FakeHttpAdapter()..body = jsonEncode({'songs': []});

      await JsonApiSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/search',
            'method': 'GET',
            'body': '{"q":"\${query}"}',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.data, isNull);
    });

    test('an answer that is not JSON is a failure', () async {
      final adapter = FakeHttpAdapter()..body = 'not json at all';

      final result = await JsonApiSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/search',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      expect(result.status.name, 'failed');
      expect(result.message, isNotNull);
    });

    test('a source without an address path asks for one', () async {
      final result = await JsonApiSourceAdapter(dio: Dio()).scan(
        MusicSourceScanRequest(
          config: config({'url': 'https://example.com/search'}),
        ),
      );

      expect(result.status.name, 'needsConfiguration');
    });
  });
}
