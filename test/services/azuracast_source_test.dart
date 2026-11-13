import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/azuracast_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// AzuraCast serves one list of stations: every station carries the address
/// it is listened on and the track that is on air.
///
/// The tests below answer the public now-playing endpoint the way a server
/// does, so the adapter is read without a server of its own.
void main() {
  group('AzuraCast adapter', () {
    test('maps the stations of the server', () async {
      final server = _AzuraServer(
        stations: [
          _entry(),
          _entry(
            shortcode: 'classical',
            name: 'Morning Classical',
            artist: 'Glenn Gould',
            title: 'Goldberg Variations',
          ),
        ],
      );
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: {'server': 'https://radio.local/'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.message, isNull);
      expect(result.songs, hasLength(2));

      final song = result.songs.first;
      expect(song.title, 'Night Jazz');
      // The station is the track; the song on air is a fact of its own.
      expect(song.artist, '');
      expect(song.album, '');
      expect(song.onAirArtist, 'Miles Davis');
      expect(song.onAirTitle, 'So What');
      expect(song.streamUrl, 'https://radio.local/listen/jazz/radio.mp3');
      expect(song.artworkUrl, 'https://radio.local/art/42.jpg');
      expect(song.genre, 'Jazz');
      expect(song.isLiveStream, isTrue);
      expect(song.externalId, 'azuracast/jazz');
      expect(song.sourceData?['provider'], 'azuracast');
      expect(song.sourceData?['stationId'], 'jazz');
      expect(song.sourceData?['codec'], 'MP3');
      expect(song.sourceData?['bitrate'], 128);
      expect(song.sourceData?['listeners'], 3);
      expect(song.sourceData?['homepage'], 'https://radio.local/public/jazz');
      expect(song.sourceData?['nowPlaying'], 'Miles Davis - So What');

      expect(server.requests.single.uri.path, '/api/nowplaying');
      expect(
        server.requests.single.headers.containsKey('X-API-Key'),
        isFalse,
      );
    });

    test('a station keeps its default mount when it names no address', () async {
      final entry = _entry(shortcode: 'chill', name: 'Chill');
      final station = entry['station'] as Map<String, dynamic>;
      station.remove('listen_url');
      station['mounts'] = [
        {'is_default': false, 'url': 'https://radio.local/first.mp3'},
        {
          'is_default': true,
          'url': 'https://radio.local/chill-64.aac',
          'bitrate': 64,
          'format': 'aac',
        },
      ];
      final server = _AzuraServer(stations: [entry]);
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      final song = result.songs.single;
      expect(song.streamUrl, 'https://radio.local/chill-64.aac');
      expect(song.sourceData?['codec'], 'AAC');
      expect(song.sourceData?['bitrate'], 64);
    });

    test('a station that cannot sound is left out', () async {
      final offline = _entry(shortcode: 'offline')..['is_online'] = false;
      final silent = _entry(shortcode: 'silent');
      (silent['station'] as Map<String, dynamic>).remove('listen_url');
      (silent['station'] as Map<String, dynamic>)['mounts'] = [];
      final server = _AzuraServer(
        stations: [offline, silent, _entry(shortcode: 'jazz')],
      );
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.songs, hasLength(1));
      expect(result.songs.single.externalId, 'azuracast/jazz');
    });

    test('a station that appears twice is read once', () async {
      final server = _AzuraServer(
        stations: [_entry(shortcode: 'jazz'), _entry(shortcode: 'jazz')],
      );
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.songs, hasLength(1));
    });

    test('a keyword narrows the stations of the server', () async {
      final server = _AzuraServer(
        stations: [
          _entry(shortcode: 'jazz', name: 'Night Jazz', description: 'Bop'),
          _entry(shortcode: 'news', name: 'World News', description: 'Talk'),
        ],
      );
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: {'server': 'https://radio.local', 'query': 'jazz'}),
        ),
      );

      expect(result.songs, hasLength(1));
      expect(result.songs.single.title, 'Night Jazz');
    });

    test('the API key of a private server is sent as a header', () async {
      final server = _AzuraServer(stations: [_entry()]);
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(
            settings: {
              'server': 'https://radio.local',
              'apiKey': 'secret',
            },
          ),
        ),
      );

      expect(server.requests.single.headers['X-API-Key'], 'secret');
    });

    test('a refused key fails the scan', () async {
      final server = _AzuraServer(stations: [_entry()], rejectKey: true);
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.azuracastAuthFailed);
    });

    test('an empty answer is reported', () async {
      final server = _AzuraServer(stations: [_entry()], emptyBody: true);
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.azuracastEmptyResponse);
    });

    test('an answer that is not a list is reported', () async {
      final server = _AzuraServer(stations: [_entry()], rawBody: '{"error": 1}');
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.azuracastEmptyResponse);
    });

    test('a server without stations says so', () async {
      final server = _AzuraServer(stations: const []);
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.azuracastNoMatch);
    });

    test('a server that is not configured asks for its settings', () async {
      final server = _AzuraServer(stations: [_entry()]);
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(settings: const {})),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
      expect(result.message, AppStrings.instance.azuracastHint);
      expect(server.requests, isEmpty);
    });

    test('a station without a track on air still plays', () async {
      final entry = _entry();
      entry.remove('now_playing');
      final server = _AzuraServer(stations: [entry]);
      final adapter = AzuracastSourceAdapter(dio: _dio(server));

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      final song = result.songs.single;
      expect(song.title, 'Night Jazz');
      expect(song.artist, isEmpty);
      expect(song.onAirArtist, isNull);
      expect(song.streamUrl, isNotEmpty);
    });
  });
}

MusicSourceConfig _config({Map<String, String>? settings}) {
  return MusicSourceConfig(
    id: 'azuracast',
    type: 'azuracast',
    name: 'AzuraCast',
    kind: MusicSourceKind.openApi,
    settings:
        settings ??
        const {'server': 'https://radio.local', 'apiKey': ''},
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

/// One station as the now-playing endpoint answers it.
Map<String, dynamic> _entry({
  String shortcode = 'jazz',
  String name = 'Night Jazz',
  String description = 'Late night jazz',
  String artist = 'Miles Davis',
  String title = 'So What',
}) {
  return {
    'station': {
      'id': shortcode == 'jazz' ? 1 : 2,
      'shortcode': shortcode,
      'name': name,
      'description': description,
      'listen_url': 'https://radio.local/listen/$shortcode/radio.mp3',
      'public_player_url': 'https://radio.local/public/$shortcode',
      'mounts': [
        {
          'is_default': true,
          'url': 'https://radio.local/listen/$shortcode/radio.mp3',
          'bitrate': 128,
          'format': 'mp3',
        },
      ],
    },
    'now_playing': {
      'song': {
        'title': title,
        'artist': artist,
        'album': 'Kind of Blue',
        'art': 'https://radio.local/art/42.jpg',
        'genre': 'Jazz',
      },
    },
    'listeners': {'current': 3, 'total': 5},
    'is_online': true,
  };
}

/// A server that answers the now-playing endpoint.
class _AzuraServer implements HttpClientAdapter {
  _AzuraServer({
    required this.stations,
    this.rejectKey = false,
    this.emptyBody = false,
    this.rawBody,
  });

  final List<Map<String, dynamic>> stations;
  final List<RequestOptions> requests = [];
  bool rejectKey;
  bool emptyBody;
  String? rawBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (rejectKey) {
      return _body('{"error": "forbidden"}', status: 401);
    }
    if (emptyBody) return _body('');
    return _body(rawBody ?? jsonEncode(stations));
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
