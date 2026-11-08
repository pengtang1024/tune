import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/itunes_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// The store answers a keyword with its songs and hands out a preview of each
/// one. The tests answer the call the way the store does and look at the
/// request the adapter sends.
void main() {
  group('iTunes adapter', () {
    test('maps a song of the store', () async {
      final server = _ItunesServer();
      final adapter = ItunesSourceAdapter(dio: server.dio);

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
      // even though the store reports the length of the whole song.
      expect(song.duration, 30000);
      expect(song.streamUrl, endsWith('.m4a'));
      expect(
        song.artworkUrl,
        endsWith('/600x600bb.jpg'),
      );
      expect(song.genre, 'Jazz');
      expect(song.year, 1959);
      expect(song.trackNumber, 1);
      expect(song.trackTotal, 5);
      expect(song.discNumber, 1);
      expect(song.totalDisc, 1);
      expect(song.externalId, '268443097');
      expect(song.description, AppStrings.instance.itunesPreviewNote);
      expect(song.sourceData?['isPreview'], isTrue);
      expect(song.sourceData?['fullDurationMs'], 547983);

      final request = server.requests.single;
      expect(request.uri.path, '/search');
      expect(request.uri.queryParameters['media'], 'music');
      expect(request.uri.queryParameters['entity'], 'song');
      expect(request.uri.queryParameters['term'], 'miles davis');
      expect(request.uri.queryParameters['country'], 'US');
      expect(request.uri.queryParameters['limit'], '10');
      expect(request.uri.queryParameters['offset'], '0');
    });

    test('a later window asks for the songs after the first ones', () async {
      final server = _ItunesServer();
      final adapter = ItunesSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'limit': '5'}),
          offset: 20,
        ),
      );

      final request = server.requests.single;
      expect(request.uri.queryParameters['limit'], '5');
      expect(request.uri.queryParameters['offset'], '20');
    });

    test('the storefront of the reader is read', () async {
      final server = _ItunesServer();
      final adapter = ItunesSourceAdapter(dio: server.dio);

      await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'country': 'jp'}),
        ),
      );

      expect(server.requests.single.uri.queryParameters['country'], 'JP');
    });

    test('the artist mode reads the songs of the artists', () async {
      final server = _ItunesServer(artists: true);
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'miles davis', 'mode': 'artists'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(result.songs.single.title, 'So What');
      expect(result.songs.single.duration, 30000);

      final search = server.requests.first;
      expect(search.uri.path, '/search');
      expect(search.uri.queryParameters['entity'], 'musicArtist');
      expect(search.uri.queryParameters['term'], 'miles davis');

      final lookup = server.requests.last;
      expect(lookup.uri.path, '/lookup');
      expect(lookup.uri.queryParameters['id'], '44984');
      expect(lookup.uri.queryParameters['entity'], 'song');
    });

    test('the artist row of a lookup is not a song', () async {
      final server = _ItunesServer(artists: true);
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': 'miles davis', 'mode': 'artists'}),
        ),
      );

      // The lookup answers the artist first; it carries no preview, so it
      // never reaches the library.
      expect(result.songs.map((song) => song.title), isNot(contains('Miles Davis')));
    });
    test('the album mode reads the albums the keyword names', () async {
      final server = _ItunesServer(albums: true);
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'mode': 'albums'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(result.songs.single.album, 'Kind of Blue');
      expect(result.songs.single.duration, 30000);

      expect(server.requests, hasLength(2));
      final search = server.requests.first;
      expect(search.uri.queryParameters['entity'], 'album');
      expect(search.uri.queryParameters['limit'], '3');
      expect(search.uri.queryParameters.containsKey('offset'), isFalse);

      final lookup = server.requests.last;
      expect(lookup.uri.path, '/lookup');
      expect(lookup.uri.queryParameters['id'], '268443092');
      expect(lookup.uri.queryParameters['entity'], 'song');
    });

    test('an album search that finds nothing asks for no lookup', () async {
      final server = _ItunesServer(albums: true, albumResults: const []);
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'mode': 'albums'}),
        ),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.itunesNoMatch);
      expect(server.requests, hasLength(1));
    });

    test('the album rows of the lookup are not songs', () async {
      final server = _ItunesServer(albums: true, withCollectionRow: true);
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'mode': 'albums'}),
        ),
      );

      // The collection row carries no preview, so only the track is kept.
      expect(result.songs, hasLength(1));
      expect(result.songs.single.title, 'So What');
    });

    test('a song without a preview is left out', () async {
      final server = _ItunesServer(
        results: [_songJson(), _songJson(preview: '')],
      );
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
    });

    test('an empty answer is reported as no match', () async {
      final server = _ItunesServer(results: const []);
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.itunesNoMatch);
    });

    test('an answer without a list is reported', () async {
      final server = _ItunesServer(broken: true);
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(config: _config()),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.message, AppStrings.instance.itunesEmptyResponse);
    });

    test('a source without a keyword asks for its settings', () async {
      final server = _ItunesServer();
      final adapter = ItunesSourceAdapter(dio: server.dio);

      final result = await adapter.scan(
        MusicSourceScanRequest(
          config: _config(settings: const {'query': '   '}),
        ),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
      expect(result.message, AppStrings.instance.itunesHint);
      expect(server.requests, isEmpty);
    });

    test('the store never offers a list of its own', () {
      expect(ItunesSourceAdapter().browseModes, isEmpty);
      expect(ItunesSourceAdapter().supportsPaging, isTrue);
      expect(
        ItunesSourceAdapter().isConfigured(
          _config(settings: const {'query': 'jazz'}),
        ),
        isTrue,
      );
    });
  });
}

MusicSourceConfig _config({Map<String, String> settings = const {}}) {
  return MusicSourceConfig(
    id: 'itunes',
    type: 'itunes',
    name: 'iTunes',
    kind: MusicSourceKind.openCatalog,
    settings: {'query': 'miles davis', 'country': 'US', ...settings},
  );
}

Map<String, dynamic> _songJson({String? preview}) {
  return {
    'wrapperType': 'track',
    'kind': 'song',
    'trackId': 268443097,
    'artistName': 'Miles Davis',
    'collectionName': 'Kind of Blue',
    'trackName': 'So What',
    'previewUrl': preview ??
        'https://audio-ssl.itunes.apple.com/preview/mzaf_1.plus.aac.p.m4a',
    'artworkUrl100':
        'https://is1-ssl.mzstatic.com/image/thumb/Music/mzi.jpg/100x100bb.jpg',
    'releaseDate': '1959-08-17T07:00:00Z',
    'discCount': 1,
    'discNumber': 1,
    'trackCount': 5,
    'trackNumber': 1,
    'trackTimeMillis': 547983,
    'primaryGenreName': 'Jazz',
    'collectionId': 268443092,
    'trackViewUrl': 'https://music.apple.com/us/album/so-what/268443092',
  };
}

/// A store that answers the call the adapter makes.
class _ItunesServer {
  _ItunesServer({
    List<Map<String, dynamic>>? results,
    List<Map<String, dynamic>>? albumResults,
    this.broken = false,
    this.albums = false,
    this.withCollectionRow = false,
    this.artists = false,
  }) : results = results ?? [_songJson()],
       albumResults =
           albumResults ??
           const [
             {
               'wrapperType': 'collection',
               'collectionId': 268443092,
               'collectionName': 'Kind of Blue',
               'artistName': 'Miles Davis',
               'trackCount': 5,
             },
           ];

  final List<Map<String, dynamic>> results;
  final List<Map<String, dynamic>> albumResults;
  final bool broken;
  final bool albums;
  final bool withCollectionRow;

  /// Answers the artist search and the artist lookup instead of the songs.
  final bool artists;
  final requests = <RequestOptions>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final Map<String, dynamic> body;
          if (broken) {
            body = {'resultCount': 0};
          } else if (artists && options.uri.queryParameters['entity'] == 'musicArtist') {
            body = {
              'resultCount': 1,
              'results': [
                {
                  'wrapperType': 'artist',
                  'artistType': 'Artist',
                  'artistId': 44984,
                  'artistName': 'Miles Davis',
                },
              ],
            };
          } else if (artists && options.uri.path == '/lookup') {
            body = {
              'resultCount': 2,
              'results': [
                {'wrapperType': 'artist', 'artistId': 44984, 'artistName': 'Miles Davis'},
                _songJson(),
              ],
            };
          } else if (albums && options.uri.path == '/search') {
            body = {
              'resultCount': albumResults.length,
              'results': albumResults,
            };
          } else if (albums) {
            body = {
              'resultCount': results.length + 1,
              'results': [
                if (withCollectionRow)
                  {
                    'wrapperType': 'collection',
                    'collectionId': 268443092,
                    'collectionName': 'Kind of Blue',
                  },
                ...results,
              ],
            };
          } else {
            body = {'resultCount': results.length, 'results': results};
          }
          handler.resolve(
            Response(
              requestOptions: options,
              data: jsonEncode(body),
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}
