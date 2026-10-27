import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/podcast_catalog_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// The open directory lists podcasts and knows the feed of every show.
///
/// The tests below read one answer of the directory and the feeds behind it:
/// which feeds a search holds, and what a scan makes of two shows, one of
/// which answers with a broken feed.
void main() {
  group('Podcast directory adapter', () {
    test('reads the feeds of a directory answer', () {
      final data = jsonDecode(_searchAnswer()) as List<dynamic>;

      expect(PodcastCatalogSourceAdapter.parseFeedUrls(data), [
        'https://a.example/feed.xml',
        'https://b.example/feed.xml',
      ]);
      expect(PodcastCatalogSourceAdapter.parseFeedUrls(const []), isEmpty);
    });

    test('a scan reads the newest episodes of every show', () async {
      final answers = _CatalogDio(
        search: _searchAnswer(),
        feeds: {
          'https://a.example/feed.xml': _feedXml('Show A', 'a'),
          'https://b.example/feed.xml': _feedXml('Show B', 'b'),
        },
      );

      final result = await PodcastCatalogSourceAdapter(
        dio: answers.dio,
      ).scan(_request('podcast_catalog', const {'query': 'jazz'}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(2));
      expect(result.songs.map((song) => song.album).toSet(), {
        'Show A',
        'Show B',
      });
      expect(answers.uris.first.host, 'gpodder.net');
      expect(answers.uris.first.path, '/search.json');
      expect(answers.uris.first.queryParameters['q'], 'jazz');
    });

    test('one broken feed does not fail the whole directory', () async {
      final answers = _CatalogDio(
        search: _searchAnswer(),
        feeds: {'https://a.example/feed.xml': _feedXml('Show A', 'a')},
      );

      final result = await PodcastCatalogSourceAdapter(
        dio: answers.dio,
      ).scan(_request('podcast_catalog', const {}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(result.songs.single.album, 'Show A');
    });

    test('a directory answer without a feed reads as no podcast', () async {
      final answers = _CatalogDio(search: '[]', feeds: const {});

      final result = await PodcastCatalogSourceAdapter(
        dio: answers.dio,
      ).scan(_request('podcast_catalog', const {}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.podcastCatalogNoMatch);
    });
  });
}

String _searchAnswer() =>
    '[{"url":"https://a.example/feed.xml"},'
    '{"url":"https://b.example/feed.xml"}]';

/// The feed of one show, with one episode.
String _feedXml(String title, String id) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
<channel>
  <title>$title</title>
  <item>
    <title>Episode of $title</title>
    <guid>episode-$id</guid>
    <enclosure url="https://cdn.example/$id.mp3" length="0" type="audio/mpeg" />
    <itunes:duration>00:12:30</itunes:duration>
  </item>
</channel>
</rss>
''';

/// One scan of the directory.
MusicSourceScanRequest _request(String id, Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: id,
      type: id,
      name: id,
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
  );
}

/// A Dio that answers the directory with its search and every feed with its
/// own document.
class _CatalogDio {
  _CatalogDio({required this.search, required this.feeds});

  final String search;
  final Map<String, String> feeds;
  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          final body = options.uri.host == 'gpodder.net'
              ? search
              : feeds[options.uri.toString()];
          if (body == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
              true,
            );
            return;
          }
          handler.resolve(
            Response(requestOptions: options, data: body, statusCode: 200),
          );
        },
      ),
    );
    return client;
  }
}
