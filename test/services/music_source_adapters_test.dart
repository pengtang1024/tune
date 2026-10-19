import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/ccmixter_source.dart';
import 'package:tune/data/services/music_sources/itunes_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/podcast_rss_source.dart';
import 'package:tune/data/services/music_sources/subsonic_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

void main() {
  group('ccMixter adapter', () {
    test('maps uploads, prefers mp3 and keeps the referer header', () async {
      final server = await _startServer((request) async {
        expect(request.uri.queryParameters['tags'], 'jazz');
        expect(request.uri.queryParameters['f'], 'json');
        await _writeJson(request, [
          {
            'upload_id': 71274,
            'upload_name': 'You were a puppet master',
            'user_name': 'JeffSpeed68',
            'upload_extra': {'usertags': 'chill,guitar,jazz'},
            'license_name': 'Attribution Noncommercial (4.0)',
            'files': [
              {
                'file_name': 'a.zip',
                'download_url': 'https://ccmixter.org/content/a.zip',
                'file_format_info': {'media-type': 'archive'},
              },
              {
                'file_name': 'a.flac',
                'download_url': 'https://ccmixter.org/content/a.flac',
                'file_format_info': {
                  'media-type': 'audio',
                  'mime_type': 'audio/x-flac',
                  'ps': '4:13',
                },
              },
              {
                'file_name': 'a.mp3',
                'download_url': 'https://ccmixter.org/content/a.mp3',
                'file_format_info': {
                  'media-type': 'audio',
                  'mime_type': 'audio/mpeg',
                  'ps': '3:16',
                },
              },
            ],
          },
          {
            'upload_id': 71275,
            'upload_name': 'No audio file',
            'user_name': 'Someone',
            'files': [
              {
                'file_name': 'b.zip',
                'download_url': 'https://ccmixter.org/content/b.zip',
                'file_format_info': {'media-type': 'archive'},
              },
            ],
          },
        ]);
      });

      final result = await CcMixterSourceAdapter(
        dio: _localDio(server.port),
      ).scan(_request('ccmixter', {'query': 'jazz'}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));

      final song = result.songs.single;
      expect(song.title, 'You were a puppet master');
      expect(song.artist, 'JeffSpeed68');
      expect(song.genre, 'chill');
      expect(song.duration, 196000);
      expect(song.streamUrl, 'https://ccmixter.org/content/a.mp3');
      expect(song.httpHeaders?['Referer'], 'https://ccmixter.org/');
      expect(song.sourceData?['license'], 'Attribution Noncommercial (4.0)');
      expect(song.sourceId, 'ccmixter');
      expect(server.port, greaterThan(0));
    });

    test('reports a missing keyword as unconfigured', () async {
      final result = await CcMixterSourceAdapter().scan(
        _request('ccmixter', const {}),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
    });
  });

  group('iTunes adapter', () {
    test('maps songs, upgrades the cover and skips everything else', () async {
      final server = await _startServer((request) async {
        expect(request.uri.queryParameters['term'], 'jazz');
        expect(request.uri.queryParameters['media'], 'music');
        expect(request.uri.queryParameters['entity'], 'song');
        await _writeJson(request, {
          'resultCount': 3,
          'results': [
            {
              'wrapperType': 'track',
              'kind': 'song',
              'trackId': 1585892546,
              'trackName': 'Jazz (We have got)',
              'artistName': 'A Tribe Called Quest',
              'collectionName': 'Jazz EP',
              'trackTimeMillis': 240000,
              'previewUrl': 'https://audio-ssl.itunes.apple.com/a.m4a',
              'artworkUrl100':
                  'https://is1-ssl.mzstatic.com/image/thumb/abc/100x100bb.jpg',
              'releaseDate': '2020-05-01T00:00:00Z',
              'primaryGenreName': 'Jazz',
            },
            {
              'wrapperType': 'track',
              'kind': 'movie',
              'trackId': 2,
              'trackName': 'The Jazz Singer',
              'previewUrl': 'https://example.com/movie.m4v',
            },
            {
              'wrapperType': 'track',
              'kind': 'song',
              'trackId': 3,
              'trackName': 'Without preview',
            },
          ],
        });
      });

      final result = await ITunesSourceAdapter(
        dio: _localDio(server.port),
      ).scan(_request('itunes', {'query': 'jazz'}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));

      final song = result.songs.single;
      expect(song.title, 'Jazz (We have got)');
      expect(song.artist, 'A Tribe Called Quest');
      expect(song.album, 'Jazz EP');
      expect(song.duration, 240000);
      expect(song.streamUrl, 'https://audio-ssl.itunes.apple.com/a.m4a');
      expect(
        song.artworkUrl,
        'https://is1-ssl.mzstatic.com/image/thumb/abc/600x600bb.jpg',
      );
      expect(song.genre, 'Jazz');
      expect(song.year, 2020);
      expect(song.sourceId, 'itunes');
      expect(server.port, greaterThan(0));
    });
  });

  group('podcast RSS adapter', () {
    test('turns the episodes of a feed into tracks', () async {
      final server = await _startServer((request) async {
        request.response.headers.contentType = ContentType(
          'application',
          'rss+xml',
          charset: 'utf-8',
        );
        request.response.write(_podcastFeed);
        await request.response.close();
      });

      final result = await PodcastRssSourceAdapter(
        dio: _localDio(server.port),
      ).scan(_request('podcast_rss', {'feed': 'http://127.0.0.1/podcast.xml'}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));

      final song = result.songs.single;
      expect(song.title, 'Episode 1');
      expect(song.artist, 'Test Podcast');
      expect(song.album, 'Test Podcast');
      expect(song.duration, 1890000);
      expect(song.streamUrl, 'https://example.com/ep1.mp3');
      expect(song.artworkUrl, 'https://example.com/episode.jpg');
      expect(song.year, 2026);
      expect(song.sourceId, 'podcast_rss');
      expect(server.port, greaterThan(0));
    });

    test('reports a broken feed as failed', () async {
      final server = await _startServer((request) async {
        request.response.write('<rss><channel><title>Broken');
        await request.response.close();
      });

      final result = await PodcastRssSourceAdapter(
        dio: _localDio(server.port),
      ).scan(_request('podcast_rss', {'feed': 'http://127.0.0.1/podcast.xml'}));

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, isNotEmpty);
    });

    test('reports a missing feed address as unconfigured', () async {
      final result = await PodcastRssSourceAdapter().scan(
        _request('podcast_rss', const {}),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
    });
  });

  group('Subsonic adapter', () {
    const password = 's3cret';

    test('signs the request and maps the answer', () async {
      final server = await _startServer((request) async {
        final query = request.uri.queryParameters;
        expect(query['u'], 'demo');
        expect(query['v'], '1.16.1');
        expect(query['c'], 'tune');
        expect(query['f'], 'json');
        expect(query['songCount'], '25');
        expect(_token(query['t']!, query['s']!, password), isTrue);

        await _writeJson(request, {
          'subsonic-response': {
            'status': 'ok',
            'version': '1.16.1',
            'search3': {
              'result': {
                'song': [
                  {
                    'id': 'tr-1',
                    'title': 'Night Drive',
                    'artist': 'Artist',
                    'album': 'Album',
                    'duration': 212,
                    'coverArt': 'al-1',
                    'suffix': 'mp3',
                    'year': 2021,
                    'genre': 'Electronic',
                  },
                  {'id': 'tr-2', 'title': 'Without suffix', 'artist': 'Artist'},
                ],
              },
            },
          },
        });
      });

      final config = _subsonicConfig(server.port, password);
      final result = await SubsonicSourceAdapter().scan(
        MusicSourceScanRequest(config: config),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(2));

      final song = result.songs.first;
      expect(song.title, 'Night Drive');
      expect(song.artist, 'Artist');
      expect(song.album, 'Album');
      expect(song.duration, 212000);
      expect(song.year, 2021);
      expect(song.genre, 'Electronic');
      expect(song.sourceId, 'subsonic');
      expect(song.playbackUri, contains('/rest/stream?id=tr-1'));

      final stream = Uri.parse(song.playbackUri);
      expect(stream.queryParameters['f'], 'mp3');
      expect(
        _token(
          stream.queryParameters['t']!,
          stream.queryParameters['s']!,
          password,
        ),
        isTrue,
      );

      final artwork = Uri.parse(song.artworkUrl!);
      expect(artwork.path, endsWith('/rest/getCoverArt'));
      expect(artwork.queryParameters['id'], 'al-1');
    });

    test('reports a rejected login as failed', () async {
      final server = await _startServer((request) async {
        await _writeJson(request, {
          'subsonic-response': {
            'status': 'failed',
            'error': {'code': 40, 'message': 'Wrong username or password'},
          },
        });
      });

      final result = await SubsonicSourceAdapter().scan(
        MusicSourceScanRequest(config: _subsonicConfig(server.port, 'wrong')),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, contains('Wrong username or password'));
    });

    test('refreshes a broken address with a new signature', () async {
      final config = _subsonicConfig(4533, password);
      final adapter = SubsonicSourceAdapter();
      final song = Song(
        id: 1,
        title: 'Night Drive',
        uri: 'tune://subsonic/tr-1',
        sourceId: 'subsonic',
        externalId: 'tr-1',
        streamUrl: 'https://old.example.com/stream',
        sourceData: {'id': 'tr-1', 'suffix': 'mp3'},
      );

      final refreshed = await adapter.refreshStream(config, song);

      expect(refreshed, isNotNull);
      final url = Uri.parse(refreshed!.streamUrl!);
      expect(url.path, endsWith('/rest/stream'));
      expect(url.queryParameters['id'], 'tr-1');
      expect(url.queryParameters['f'], 'mp3');
      expect(
        _token(url.queryParameters['t']!, url.queryParameters['s']!, password),
        isTrue,
      );
      expect(refreshed.streamUrl, isNot('https://old.example.com/stream'));
    });

    test('reports missing credentials as unconfigured', () async {
      final result = await SubsonicSourceAdapter().scan(
        MusicSourceScanRequest(
          config: const MusicSourceConfig(
            id: 'subsonic',
            name: 'Subsonic',
            kind: MusicSourceKind.openApi,
          ),
        ),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
    });
  });
}

MusicSourceScanRequest _request(String sourceId, Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: sourceId,
      name: sourceId,
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
  );
}

MusicSourceConfig _subsonicConfig(int port, String password) {
  return MusicSourceConfig(
    id: 'subsonic',
    name: 'Subsonic',
    kind: MusicSourceKind.openApi,
    settings: {
      'server': 'http://127.0.0.1:$port',
      'user': 'demo',
      'password': password,
    },
  );
}

/// Checks the salted token the Subsonic protocol expects.
bool _token(String token, String salt, String password) {
  return md5.convert(utf8.encode('$password$salt')).toString() == token;
}

Future<HttpServer> _startServer(
  Future<void> Function(HttpRequest request) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  server.listen((request) async {
    try {
      await handler(request);
    } finally {
      await request.response.close();
    }
  });
  return server;
}

/// Sends every request of a client to the local test server.
///
/// The adapters keep their real endpoint, only the host is replaced, so the
/// whole request path is exercised over a real socket.
Dio _localDio(int port) {
  final dio = Dio();
  dio.httpClientAdapter = _LocalAdapter(Uri.parse('http://127.0.0.1:$port'));
  return dio;
}

class _LocalAdapter implements HttpClientAdapter {
  _LocalAdapter(this.origin);

  final Uri origin;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final target = origin.replace(
      path: options.uri.path,
      queryParameters: options.uri.queryParameters,
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(target);
      final response = await request.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      final headers = <String, List<String>>{};
      response.headers.forEach((name, values) {
        headers[name] = values;
      });
      return ResponseBody.fromBytes(
        bytes,
        response.statusCode,
        headers: headers,
      );
    } finally {
      client.close(force: true);
    }
  }
}

Future<void> _writeJson(HttpRequest request, Object body) async {
  // The real services answer with `text/plain` or `text/javascript`, so the
  // mock does the same.
  request.response.headers.contentType = ContentType.text;
  request.response.write(jsonEncode(body));
  await request.response.close();
}

const _podcastFeed = '''<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
  <channel>
    <title>Test Podcast</title>
    <itunes:image href="https://example.com/cover.jpg"/>
    <item>
      <title>Episode 1</title>
      <itunes:duration>00:31:30</itunes:duration>
      <enclosure url="https://example.com/ep1.mp3" type="audio/mpeg" length="1000"/>
      <itunes:image href="https://example.com/episode.jpg"/>
      <pubDate>Tue, 06 Oct 2026 09:00:00 +0000</pubDate>
      <guid isPermaLink="false">ep-1</guid>
    </item>
    <item>
      <title>Episode without audio</title>
    </item>
  </channel>
</rss>
''';
