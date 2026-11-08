import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/podcast_apple_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Apple's directory names shows; the episodes of a show come from its feed.
///
/// The tests answer the calls the way the directory does: a chart of show ids,
/// one lookup that turns the ids into feeds, a search that answers with feeds,
/// and a feed per show with its newest episodes.
void main() {
  group('Apple Podcasts directory', () {
    test('reads the shows of the chart', () async {
      final server = _AppleServer();
      final adapter = PodcastAppleSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(settings: const {'limit': '2'})),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.message, isNull);
      expect(result.songs, hasLength(2));

      // The chart order is kept: the first show of the chart comes first even
      // though the lookup answered in another order.
      expect(result.songs.first.title, 'Episode A');
      expect(result.songs.first.album, 'Chart One');
      expect(result.songs.first.artist, 'Host One');
      expect(result.songs.first.streamUrl, 'https://cdn.example.com/one.mp3');
      expect(result.songs.first.externalId, 'ep-a');
      expect(result.songs.last.album, 'Chart Two');

      final charts = server.requests.first;
      expect(charts.uri.path, '/us/rss/toppodcasts/limit=2/json');
      final lookup = server.requests[1];
      expect(lookup.uri.path, '/lookup');
      expect(lookup.uri.queryParameters['id'], '111,222');
    });

    test('a keyword searches the directory', () async {
      final server = _AppleServer();
      final adapter = PodcastAppleSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'jazz', 'country': 'US'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs.single.album, 'Search Show');

      final search = server.requests.first;
      expect(search.uri.path, '/search');
      expect(search.uri.queryParameters['media'], 'podcast');
      expect(search.uri.queryParameters['term'], 'jazz');
      expect(search.uri.queryParameters['country'], 'US');
      expect(search.uri.queryParameters['limit'], '5');
    });

    test('the storefront of the reader is read', () async {
      final server = _AppleServer();
      final adapter = PodcastAppleSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'country': 'cn', 'limit': '2'}),
        ),
      );

      expect(
        server.requests.first.uri.path,
        '/cn/rss/toppodcasts/limit=2/json',
      );
    });

    test('a category narrows the chart to one of its own', () async {
      final server = _AppleServer();
      final adapter = PodcastAppleSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(
            settings: const {'country': 'US', 'genre': '1318', 'limit': '2'},
          ),
        ),
      );

      // The store files a category under its own number, and the chart of
      // that category is a path of its own.
      expect(
        server.requests.first.uri.path,
        '/us/rss/toppodcasts/limit=2/genre=1318/json',
      );
    });

    test('a number the store does not file is not put in the path', () async {
      final server = _AppleServer();
      final adapter = PodcastAppleSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(
            settings: const {'country': 'US', 'genre': '9999', 'limit': '2'},
          ),
        ),
      );

      // A number the store does not know would answer with another chart, so
      // the whole chart is read instead of pretending to narrow it.
      expect(
        server.requests.first.uri.path,
        '/us/rss/toppodcasts/limit=2/json',
      );
    });

    test('a broken feed leaves the other shows in the scan', () async {
      final server = _AppleServer(
        brokenFeed: 'https://feeds.example.com/one.xml',
      );
      final adapter = PodcastAppleSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(settings: const {'limit': '2'})),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(result.songs.single.album, 'Chart Two');
    });

    test('an empty chart is reported as no match', () async {
      final server = _AppleServer(chartIds: const []);
      final adapter = PodcastAppleSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.podcastAppleNoMatch);
      expect(server.requests, hasLength(1));
    });

    test('a lookup without a feed is reported as no match', () async {
      final server = _AppleServer(feedUrls: const {});
      final adapter = PodcastAppleSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.podcastAppleNoMatch);
    });

    test('the chart ids are read in order and once each', () {
      final ids = PodcastAppleSourceAdapter.parseTopIds({
        'feed': {
          'entry': [
            {
              'id': {
                'attributes': {'im:id': '111'},
              },
            },
            {
              'id': {
                'attributes': {'im:id': '222'},
              },
            },
            {
              'id': {
                'attributes': {'im:id': '111'},
              },
            },
          ],
        },
      });

      expect(ids, ['111', '222']);
    });

    test('the feeds of a search are read once each', () {
      final feeds = PodcastAppleSourceAdapter.parseSearchFeeds({
        'results': [
          {'feedUrl': 'https://feeds.example.com/one.xml'},
          {'feedUrl': 'https://feeds.example.com/one.xml'},
          {'feedUrl': 'not-a-url'},
          {'feedUrl': 'https://feeds.example.com/two.xml'},
        ],
      });

      expect(feeds, [
        'https://feeds.example.com/one.xml',
        'https://feeds.example.com/two.xml',
      ]);
    });
  });
}

MusicSourceConfig _config({Map<String, String> settings = const {}}) {
  return MusicSourceConfig(
    id: 'podcast_apple',
    type: 'podcast_apple',
    name: 'Apple Podcasts',
    kind: MusicSourceKind.openCatalog,
    settings: {'query': '', 'country': 'US', 'limit': '5', ...settings},
  );
}

/// A directory that answers the calls the adapter makes.
class _AppleServer {
  _AppleServer({
    List<String>? chartIds,
    Map<String, String>? feedUrls,
    this.brokenFeed,
  }) : chartIds = chartIds ?? const ['111', '222'],
       feedUrls =
           feedUrls ??
           const {
             '111': 'https://feeds.example.com/one.xml',
             '222': 'https://feeds.example.com/two.xml',
           };

  final List<String> chartIds;
  final Map<String, String> feedUrls;

  /// A feed address the server refuses, as a broadcaster that went away.
  final String? brokenFeed;

  final requests = <RequestOptions>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final path = options.uri.path;

          if (path == '/lookup') {
            handler.resolve(
              _json({
                'resultCount': feedUrls.length,
                'results': [
                  for (final entry in feedUrls.entries)
                    {
                      'collectionId': int.tryParse(entry.key),
                      'feedUrl': entry.value,
                    },
                ],
              }, options),
            );
            return;
          }

          if (path == '/search') {
            handler.resolve(
              _json({
                'resultCount': 1,
                'results': [
                  {'feedUrl': 'https://feeds.example.com/search.xml'},
                ],
              }, options),
            );
            return;
          }

          if (path.endsWith('/json')) {
            handler.resolve(
              _json({
                'feed': {
                  'entry': [
                    for (final id in chartIds)
                      {
                        'id': {
                          'attributes': {'im:id': id},
                        },
                      },
                  ],
                },
              }, options),
            );
            return;
          }

          if (options.uri.toString() == brokenFeed) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: options, statusCode: 404),
              ),
            );
            return;
          }

          handler.resolve(
            _text(_feedXml(album: _albumOf(options.uri.toString())), options),
          );
        },
      ),
    );
    return client;
  }

  static String _albumOf(String url) {
    if (url.contains('one.xml')) return 'Chart One';
    if (url.contains('search.xml')) return 'Search Show';
    return 'Chart Two';
  }

  static Response<dynamic> _json(
    Map<String, dynamic> body,
    RequestOptions options,
  ) {
    return Response(
      requestOptions: options,
      data: jsonEncode(body),
      statusCode: 200,
    );
  }

  static Response<dynamic> _text(String body, RequestOptions options) {
    return Response(requestOptions: options, data: body, statusCode: 200);
  }
}

String _feedXml({required String album}) {
  final author = album == 'Chart One' ? 'Host One' : 'Host Two';
  final file = album == 'Chart One' ? 'one' : 'two';
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>$album</title>
    <item>
      <title>Episode ${album == 'Chart One' ? 'A' : 'B'}</title>
      <guid>ep-${album == 'Chart One' ? 'a' : 'b'}</guid>
      <enclosure url="https://cdn.example.com/$file.mp3" type="audio/mpeg"/>
      <author>$author</author>
      <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>
''';
}
