import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/peertube_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// PeerTube spreads one band's music over many videos, and the video list
/// does not carry the files: the playable address lives in the detail of each
/// video, and a video may have been transcoded to audio only.
///
/// The tests below answer the calls the way a server does: a list of videos in
/// the music category, a search across the federation, and a detail per video
/// with its files.
void main() {
  group('PeerTube adapter', () {
    test('maps a video through its audio-only file', () async {
      final server = _PeerTubeServer();
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(extra: {'limit': '10'})),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.message, isNull);
      expect(result.songs, hasLength(1));

      final song = result.songs.single;
      expect(song.title, 'Late Night Session');
      expect(song.artist, 'The Canal Club');
      expect(song.album, '');
      expect(song.duration, 754000);
      expect(
        song.streamUrl,
        'https://video.local/static/web-videos/uuid-1-audio.mp3',
      );
      expect(
        song.artworkUrl,
        'https://video.local/static/thumbnails/uuid-1.jpg',
      );
      expect(song.genre, 'Music');
      expect(song.year, 2024);
      expect(song.size, 1200);
      expect(song.license, 'Attribution - Share Alike');
      expect(
        song.description,
        'A live set recorded in Paris',
      );
      expect(song.externalId, 'uuid-1');
      expect(song.sourceData?['pageUrl'], 'https://video.local/w/uuid-1');
      expect(song.sourceData?['views'], 42);

      final list = _request(server, '/api/v1/videos');
      expect(list.uri.queryParameters['count'], '10');
      expect(list.uri.queryParameters['start'], '0');
      expect(list.uri.queryParameters['sort'], '-views');
      expect(list.uri.queryParameters['categoryOneOf'], '1');
      expect(list.uri.queryParameters['nsfw'], 'false');
    });

    test('the latest order asks the server for the newest videos', () async {
      final server = _PeerTubeServer();
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      await adapter.scan(
        MusicSourceScanRequest(config: _config(extra: {'browse': 'latest'})),
      );

      final list = _request(server, '/api/v1/videos');
      expect(list.uri.queryParameters['sort'], '-publishedAt');
    });

    test('a keyword searches the federation', () async {
      final server = _PeerTubeServer();
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(extra: {'query': '  jazz  '}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      final search = _request(server, '/api/v1/search/videos');
      expect(search.uri.queryParameters['search'], 'jazz');
      expect(search.uri.queryParameters['categoryOneOf'], '1');
      expect(search.uri.queryParameters.containsKey('sort'), isFalse);
    });

    test('the everything catalogue leaves the category at the server', () async {
      final server = _PeerTubeServer();
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      await adapter.scan(
        MusicSourceScanRequest(config: _config(extra: {'category': 'all'})),
      );

      final list = _request(server, '/api/v1/videos');
      expect(list.uri.queryParameters.containsKey('categoryOneOf'), isFalse);
    });

    test('a later window is read from the start the window begins at', () async {
      final server = _PeerTubeServer();
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(), offset: 20),
      );

      expect(result.status, SourceScanStatus.success);
      final list = _request(server, '/api/v1/videos');
      expect(list.uri.queryParameters['start'], '20');
    });

    test('a video without an audio-only file plays its smallest file', () async {
      final server = _PeerTubeServer(
        videos: [_videoJson(uuid: 'uuid-2')],
        details: {
          'uuid-2': _videoDetail(
            uuid: 'uuid-2',
            files: [
              _file(url: 'https://video.local/big.mp4', size: 900, height: 720),
              _file(url: 'https://video.local/small.mp4', size: 200, height: 240),
              _file(
                url: 'https://video.local/silent.mp4',
                size: 50,
                height: 144,
                hasAudio: false,
              ),
            ],
          ),
        },
      );
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.songs.single.streamUrl, 'https://video.local/small.mp4');
    });

    test('a live stream is left out', () async {
      final server = _PeerTubeServer(
        videos: [
          _videoJson(uuid: 'uuid-1'),
          _videoJson(uuid: 'uuid-live', live: true),
        ],
      );
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.songs, hasLength(1));
      expect(result.songs.single.externalId, 'uuid-1');
    });

    test('a video without a file to play is left out', () async {
      final server = _PeerTubeServer(
        videos: [
          _videoJson(uuid: 'uuid-1'),
          _videoJson(uuid: 'uuid-empty'),
        ],
        details: {
          'uuid-1': _videoDetail(uuid: 'uuid-1'),
          'uuid-empty': _videoDetail(uuid: 'uuid-empty', files: const []),
        },
      );
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.songs, hasLength(1));
      expect(result.songs.single.externalId, 'uuid-1');
    });

    test('a video whose detail cannot be read is left out', () async {
      final server = _PeerTubeServer(
        videos: [
          _videoJson(uuid: 'uuid-1'),
          _videoJson(uuid: 'uuid-gone'),
        ],
      );
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(result.songs.single.externalId, 'uuid-1');
    });

    test('an empty catalogue is reported as no match', () async {
      final server = _PeerTubeServer(videos: const []);
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.peerTubeNoMatch);
    });

    test('an address that is not a PeerTube server is reported', () async {
      final server = _PeerTubeServer(page: true);
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.peerTubeEmptyResponse);
    });

    test('a server that is not configured asks for its settings', () async {
      final server = _PeerTubeServer();
      final adapter = PeerTubeSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(configured: false)),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
      expect(result.message, AppStrings.instance.peerTubeHint);
      expect(server.requests, isEmpty);
    });
  });
}

RequestOptions _request(_PeerTubeServer server, String path) =>
    server.requests.firstWhere((request) => request.uri.path == path);

MusicSourceConfig _config({
  Map<String, String>? extra,
  bool configured = true,
}) {
  return MusicSourceConfig(
    id: 'peertube',
    type: 'peertube',
    name: 'PeerTube',
    kind: MusicSourceKind.openCatalog,
    settings: configured
        ? {
            'server': 'https://video.local',
            'query': '',
            'category': 'music',
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

Map<String, dynamic> _videoJson({
  String uuid = 'uuid-1',
  bool live = false,
}) => {
  'uuid': uuid,
  'shortUUID': uuid,
  'name': 'Late Night Session',
  'isLive': live,
  'duration': 754,
  'publishedAt': '2024-06-01T18:30:00.000Z',
  'thumbnailPath': '/static/thumbnails/$uuid.jpg',
  'previewPath': '/static/previews/$uuid.jpg',
  'url': 'https://video.local/w/$uuid',
  'views': 42,
  'category': {'id': 1, 'label': 'Music'},
  'licence': {'id': 2, 'label': 'Attribution - Share Alike'},
  'channel': {'displayName': 'The Canal Club'},
  'account': {'displayName': 'canal'},
  'description': 'A **live** set\nrecorded in Paris',
  'truncatedDescription': 'A **live** set',
};

Map<String, dynamic> _videoDetail({
  String uuid = 'uuid-1',
  List<Map<String, dynamic>>? files,
}) => {
  ..._videoJson(uuid: uuid),
  'files': files ?? [_file(url: 'https://video.local/static/web-videos/$uuid-audio.mp3', size: 1200, audioOnly: true)],
};

Map<String, dynamic> _file({
  required String url,
  int size = 100,
  int height = 240,
  bool hasAudio = true,
  bool audioOnly = false,
}) => {
  'fileUrl': url,
  'fileDownloadUrl': url,
  'size': size,
  'hasAudio': hasAudio,
  'hasVideo': !audioOnly,
  'resolution': audioOnly ? {'id': 0, 'label': 'Audio only'} : {'id': height, 'label': '${height}p'},
};

/// A server that answers the calls the adapter makes.
class _PeerTubeServer implements HttpClientAdapter {
  _PeerTubeServer({
    List<Map<String, dynamic>>? videos,
    Map<String, Map<String, dynamic>>? details,
    this.page = false,
  }) : videos = videos ?? [_videoJson()],
       details = details ?? {'uuid-1': _videoDetail()};

  final List<Map<String, dynamic>> videos;
  final Map<String, Map<String, dynamic>> details;

  /// Answers every call with a page, the way a web site does.
  final bool page;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.uri.path;

    if (page) return _body('<html><body>Not a server</body></html>');

    if (path.startsWith('/api/v1/videos/')) {
      final uuid = path.split('/').last;
      final detail = details[uuid];
      if (detail == null) {
        return _body('{"error": "not found"}', status: 404);
      }
      return _body(jsonEncode(detail));
    }

    if (path == '/api/v1/search/videos') {
      final keyword = options.uri.queryParameters['search'] ?? '';
      final hits = videos
          .where((video) => '${video['name']}'.contains(keyword))
          .toList();
      return _body(jsonEncode({'total': hits.length, 'data': hits}));
    }

    if (path == '/api/v1/videos') {
      return _body(jsonEncode({'total': videos.length, 'data': videos}));
    }

    return _body('{}');
  }

  @override
  void close({bool force = false}) {}

  static ResponseBody _body(String text, {int status = 200}) {
    final bytes = Uint8List.fromList(utf8.encode(text));
    return ResponseBody(
      Stream<Uint8List>.value(bytes),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
