import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/graphql_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';

import 'fake_http_adapter.dart';

/// The reader asks an interface with a document of their own.
///
/// The document is a query, not a script: the app sends it as it is and
/// reads the answer with the same paths the JSON interface uses.
void main() {
  group('the scan of a GraphQL interface', () {
    MusicSourceConfig config(Map<String, String> settings) {
      return MusicSourceConfig(
        id: 'graphql-1',
        type: 'graphql',
        name: 'GraphQL',
        kind: MusicSourceKind.custom,
        settings: settings,
      );
    }

    Dio dioOf(FakeHttpAdapter adapter) {
      return Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter;
    }

    test('the document and the variables are sent as one request', () async {
      final adapter = FakeHttpAdapter()
        ..body = jsonEncode({
          'data': {
            'tracks': [
              {
                'id': '1',
                'title': 'Night Drive',
                'url': 'https://example.com/1.mp3',
              },
            ],
          },
        });

      final result = await GraphqlSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/graphql',
            'document': 'query Tracks(\$q: String) { tracks(q: \$q) { id } }',
            'variables': '{"q":"\${query}"}',
            'query': 'night drive',
            'listPath': 'data.tracks',
            'idPath': 'id',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.songs.single.title, 'Night Drive');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.data, {
        'query': 'query Tracks(\$q: String) { tracks(q: \$q) { id } }',
        'variables': {'q': 'night drive'},
      });
    });

    test('the answer is read with the paths of the mapping', () async {
      final adapter = FakeHttpAdapter()
        ..body = jsonEncode({
          'data': {
            'tracks': [
              {
                'id': '1',
                'title': 'Night Drive',
                'artist': 'Nova',
                'url': 'https://example.com/1.mp3',
              },
            ],
          },
        });

      final result = await GraphqlSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/graphql',
            'document': 'query { tracks { id } }',
            'listPath': 'data.tracks',
            'idPath': 'id',
            'titlePath': 'title',
            'artistPath': 'artist',
            'urlPath': 'url',
          }),
        ),
      );

      expect(result.songs.single.artist, 'Nova');
      expect(result.songs.single.streamUrl, 'https://example.com/1.mp3');
    });

    test('the headers are sent as they are written', () async {
      final adapter = FakeHttpAdapter()..body = jsonEncode({'data': {}});

      await GraphqlSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/graphql',
            'document': 'query { tracks { id } }',
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

    test('an answer that is not JSON is a failure', () async {
      final adapter = FakeHttpAdapter()..body = 'not json at all';

      final result = await GraphqlSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'https://example.com/graphql',
            'document': 'query { tracks { id } }',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      expect(result.status.name, 'failed');
    });

    test('an address that is not http(s) is not asked', () async {
      final adapter = FakeHttpAdapter()..body = jsonEncode({'data': {}});

      final result = await GraphqlSourceAdapter(dio: dioOf(adapter)).scan(
        MusicSourceScanRequest(
          config: config({
            'url': 'file:///etc/passwd',
            'document': 'query { tracks { id } }',
            'titlePath': 'title',
            'urlPath': 'url',
          }),
        ),
      );

      expect(result.status.name, 'failed');
      expect(adapter.requestedUrls, isEmpty);
    });

    test('a source without a document asks for one', () async {
      final result = await GraphqlSourceAdapter(dio: Dio()).scan(
        MusicSourceScanRequest(
          config: config({'url': 'https://example.com/graphql'}),
        ),
      );

      expect(result.status.name, 'needsConfiguration');
    });
  });

  group('trying a mapping out', () {
    MusicSourceConfig config(Map<String, String> settings) {
      return MusicSourceConfig(
        id: 'graphql-1',
        type: 'graphql',
        name: 'GraphQL',
        kind: MusicSourceKind.custom,
        settings: settings,
      );
    }

    Dio dioOf(FakeHttpAdapter adapter) {
      return Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter;
    }

    test('the paths the answer suggests are offered to the reader', () async {
      final adapter = FakeHttpAdapter()
        ..body = jsonEncode({
          'data': {
            'tracks': [
              {
                'id': '1',
                'title': 'Night Drive',
                'url': 'https://example.com/1.mp3',
              },
            ],
          },
        });

      final preview = await GraphqlSourceAdapter(dio: dioOf(adapter)).preview(
        config({
          'url': 'https://example.com/graphql',
          'document': 'query { tracks { id title url } }',
        }),
      );

      expect(preview, isNotNull);
      expect(preview!.suggestions['listPath'], 'data.tracks');
      expect(preview.suggestions['titlePath'], 'title');
      expect(preview.songs.map((song) => song.title), ['Night Drive']);
    });
  });
}
