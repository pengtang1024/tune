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

    test('the playlist mode reads the playlists the keyword names', () async {
      final server = _DeezerServer(playlists: true);
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'smooth jazz', 'mode': 'playlists'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(result.songs.first.title, 'So What');
      expect(result.songs.first.album, 'Kind of Blue');
      expect(result.songs.first.duration, 30000);

      expect(server.requests.first.uri.path, '/search/playlist');
      expect(server.requests[1].uri.path, '/playlist/5314690902');
    });

    test('a playlist without songs is skipped', () async {
      final server = _DeezerServer(playlists: true, emptyPlaylist: true);
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'smooth jazz', 'mode': 'playlists'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.deezerNoMatch);
    });
    test('the artist mode reads the top songs of the artists', () async {
      final server = _DeezerServer(artists: true);
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'miles davis', 'mode': 'artists'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(2));
      expect(result.songs.first.artist, 'Miles Davis');
      expect(result.songs.first.duration, 30000);

      expect(server.requests.first.uri.path, '/search/artist');
      expect(server.requests.first.uri.queryParameters['q'], 'miles davis');
      expect(server.requests[1].uri.path, '/artist/1910/top');
      expect(server.requests[1].uri.queryParameters['limit'], '20');
    });

    test('an artist without top songs is skipped', () async {
      final server = _DeezerServer(artists: true, emptyArtistTop: true);
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'miles davis', 'mode': 'artists'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.deezerNoMatch);
    });
    test('the album mode reads the albums the keyword names', () async {
      final server = _DeezerServer(albums: true);
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'kind of blue', 'mode': 'albums'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(2));
      // The tracks of an album carry no album of their own; the record fills
      // the name and the cover in.
      expect(result.songs.first.album, 'Kind of Blue');
      expect(result.songs.first.artworkUrl, endsWith('/1000x1000-000000-80-0-0.jpg'));
      expect(result.songs.first.duration, 30000);

      expect(server.requests.first.uri.path, '/search/album');
      expect(server.requests.first.uri.queryParameters['q'], 'kind of blue');
      expect(server.requests[1].uri.path, '/album/1441464');
    });

    test('the album mode reads the chart of albums without a keyword', () async {
      final server = _DeezerServer(albums: true, albumsWithoutKeyword: true);
      final adapter = DeezerSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config(settings: const {'mode': 'albums'})),
      );

      // The catalogue serves a chart of albums, so the album mode works
      // without a keyword too.
      expect(result.status, SourceScanStatus.success);
      expect(server.requests.first.uri.path, '/chart/0/albums');
      expect(server.requests[1].uri.path, '/album/1441464');
      expect(result.songs, isNotEmpty);
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
  _DeezerServer({
    List<Map<String, dynamic>>? data,
    this.broken = false,
    this.albums = false,
    this.albumsWithoutKeyword = false,
    this.artists = false,
    this.playlists = false,
    this.emptyPlaylist = false,
    this.emptyArtistTop = false,
  }) : data = data ?? [_songJson()];

  final List<Map<String, dynamic>> data;
  final bool broken;

  /// Answers the album search and the album detail instead of the charts.
  final bool albums;

  /// Answers the chart of albums; the album mode may run without a keyword.
  final bool albumsWithoutKeyword;

  /// Answers the artist search and the top songs instead of the charts.
  final bool artists;

  /// Answers the top songs of an artist with nothing.
  final bool emptyArtistTop;

  /// Answers the playlist search and the playlist detail instead of the charts.
  final bool playlists;

  /// Answers a playlist with no song.
  final bool emptyPlaylist;
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
                data: jsonEncode({
                  'error': {'message': 'no data'},
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          final path = options.uri.path;
          if (playlists && path == '/search/playlist') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'data': [
                    {'id': 5314690902, 'title': 'Smooth Jazz', 'nb_tracks': 2},
                  ],
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          if (playlists && path.startsWith('/playlist/')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'id': 5314690902,
                  'title': 'Smooth Jazz',
                  'tracks': {
                    'data': emptyPlaylist ? <dynamic>[] : data,
                  },
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          if (artists && path == '/search/artist') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'data': [
                    {'id': 1910, 'name': 'Miles Davis', 'nb_album': 320},
                  ],
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          if (artists && path.startsWith('/artist/')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'data': emptyArtistTop
                      ? <dynamic>[]
                      : [
                          _albumTrack('So What', 3818963601, 'Miles Davis'),
                          _albumTrack('Blue In Green', 3818963602, 'Miles Davis'),
                        ],
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          if (albums && albumsWithoutKeyword && path == '/chart/0/albums') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'data': [
                    {'id': 1441464, 'title': 'Kind of Blue'},
                  ],
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          if (albums && path == '/search/album') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'data': [
                    {'id': 1441464, 'title': 'Kind of Blue', 'nb_tracks': 2},
                  ],
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          if (albums && path.startsWith('/album/')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: jsonEncode({
                  'id': 1441464,
                  'title': 'Kind of Blue',
                  'cover_xl':
                      'https://cdn-images.example.com/cover/abc/1000x1000-000000-80-0-0.jpg',
                  'artist': {'id': 44984, 'name': 'Miles Davis'},
                  'tracks': {
                    'data': [
                      _albumTrack('So What', 3818963601),
                      _albumTrack('Blue In Green', 3818963602),
                    ],
                  },
                }),
                statusCode: 200,
              ),
            );
            return;
          }
          if (path.startsWith('/track/')) {
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

  /// A track of an album answer: no album of its own, no cover.
  ///
  /// A track of an artist answer names its artist, so the caller may add one.
  static Map<String, dynamic> _albumTrack(
    String title,
    int id, [
    String? artist,
  ]) {
    return {
      'id': id,
      'title': title,
      'duration': 545,
      'preview': 'https://cdnt-preview.example.com/$id.mp3',
      if (artist != null) 'artist': {'id': 1910, 'name': artist},
      if (artist != null)
        'album': {
          'id': 1441464,
          'title': 'Kind of Blue',
          'cover_xl':
              'https://cdn-images.example.com/cover/abc/1000x1000-000000-80-0-0.jpg',
        },
    };
  }
}
