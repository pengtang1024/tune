import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/audius_source.dart';
import 'package:tune/data/services/music_sources/ccmixter_source.dart';
import 'package:tune/data/services/music_sources/funkwhale_source.dart';
import 'package:tune/data/services/music_sources/audiobookshelf_source.dart';
import 'package:tune/data/services/music_sources/emby_source.dart';
import 'package:tune/data/services/music_sources/jellyfin_source.dart';
import 'package:tune/data/services/music_sources/plex_source.dart';
import 'package:tune/data/services/music_sources/radio_source.dart';
import 'package:tune/data/services/music_sources/subsonic_source.dart';
import 'package:tune/data/services/music_sources/wikimedia_source.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/librivox_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
import 'package:tune/domain/models/music_source.dart';

/// A source that serves its list in pages answers a later offset with the
/// next window, so the search panel can ask for more without repeating.
void main() {
  group('paging', () {
    test('Openverse asks for the page that holds the offset', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await OpenverseSourceAdapter(
        dio: captured.dio,
      ).scan(_request('openverse', offset: 20));

      expect(captured.uri?.queryParameters['page'], '2');
      expect(captured.uri?.queryParameters['page_size'], '20');
    });

    test('Audius passes the offset through', () async {
      final captured = _Captured(body: {'data': <dynamic>[]});

      await AudiusSourceAdapter(
        dio: captured.dio,
      ).scan(_request('audius', offset: 40));

      expect(captured.uri?.queryParameters['offset'], '40');
    });

    test('the Internet Archive asks for the page of the offset', () async {
      final captured = _Captured(
        body: {
          'response': {'docs': <dynamic>[]},
        },
      );

      await InternetArchiveSourceAdapter(
        dio: captured.dio,
      ).scan(_request('internet_archive', offset: 8));

      expect(captured.uri?.queryParameters['page'], '2');
    });

    test('LibriVox passes the offset to the catalogue', () async {
      final captured = _Captured(body: {'books': <dynamic>[]});

      await LibrivoxSourceAdapter(
        dio: captured.dio,
      ).scan(_request('librivox', offset: 8, settings: {'query': 'jazz'}));

      expect(captured.uris.first.queryParameters['offset'], '8');
    });

    test('ccMixter passes the offset to the query', () async {
      final captured = _Captured(body: '[]');

      await CcMixterSourceAdapter(
        dio: captured.dio,
      ).scan(_request('ccmixter', offset: 20));

      expect(captured.uri?.queryParameters['offset'], '20');
    });

    test('Funkwhale asks for the page of the offset', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await FunkwhaleSourceAdapter(dio: captured.dio).scan(
        _request(
          'funkwhale',
          offset: 20,
          settings: {'server': 'https://fw.example'},
        ),
      );

      expect(captured.uri?.queryParameters['page'], '2');
    });

    test('Radio Browser passes the offset through', () async {
      final captured = _Captured(body: <dynamic>[]);

      await RadioSourceAdapter(
        dio: captured.dio,
      ).scan(_request('radio', offset: 20, settings: {'provider': 'browser'}));

      expect(captured.uri?.queryParameters['offset'], '20');
    });

    test('Wikimedia passes the offset to the search stream', () async {
      final captured = _Captured(
        body: {
          'query': {'pages': <dynamic>{}},
        },
      );

      await WikimediaSourceAdapter(
        dio: captured.dio,
      ).scan(_request('wikimedia', offset: 2, settings: {'query': 'jazz'}));

      expect(captured.uri?.queryParameters['gsroffset'], '2');
      expect(captured.uri?.queryParameters['generator'], 'search');
    });

    test('Wikimedia has no later window for the category stream', () async {
      final captured = _Captured(
        body: {
          'query': {'pages': <dynamic>{}},
        },
      );

      final result = await WikimediaSourceAdapter(
        dio: captured.dio,
      ).scan(_request('wikimedia', offset: 2));

      expect(result.songs, isEmpty);
      expect(captured.uris, isEmpty);
    });

    test('Jellyfin asks for the window at the offset', () async {
      final routed = _RoutedDio({
        '/Users/AuthenticateByName': {'AccessToken': 'tok'},
        '/Items': {'Items': <dynamic>[]},
      });

      await JellyfinSourceAdapter(dio: routed.dio).scan(
        _request(
          'jellyfin',
          offset: 50,
          settings: {'server': 'http://x', 'user': 'u', 'password': 'p'},
        ),
      );

      final items = routed.uris.firstWhere(
        (uri) => uri.path.endsWith('/Items'),
      );
      expect(items.queryParameters['StartIndex'], '50');
    });

    test('Emby asks for the window at the offset', () async {
      final routed = _RoutedDio({
        '/Users/AuthenticateByName': {'AccessToken': 'tok'},
        '/Items': {'Items': <dynamic>[]},
      });

      await EmbySourceAdapter(dio: routed.dio).scan(
        _request(
          'emby',
          offset: 25,
          settings: {'server': 'http://x', 'user': 'u', 'password': 'p'},
        ),
      );

      final items = routed.uris.firstWhere(
        (uri) => uri.path.endsWith('/Items'),
      );
      expect(items.queryParameters['StartIndex'], '25');
    });

    test('Plex asks for the window at the offset', () async {
      final routed = _RoutedDio({
        '/library/sections':
            '<MediaContainer><Directory key="2" type="artist" /></MediaContainer>',
        '/all': '<MediaContainer />',
      });

      await PlexSourceAdapter(dio: routed.dio).scan(
        _request(
          'plex',
          offset: 40,
          settings: {'server': 'http://x', 'token': 't'},
        ),
      );

      final all = routed.uris.firstWhere((uri) => uri.path.endsWith('/all'));
      expect(all.queryParameters['X-Plex-Container-Start'], '40');
    });

    test('Subsonic asks for the window at the offset', () async {
      final routed = _RoutedDio({
        'search3': {
          'subsonic-response': {
            'status': 'ok',
            'searchResult3': {'song': <dynamic>[]},
          },
        },
      });

      await SubsonicSourceAdapter(dio: routed.dio).scan(
        _request(
          'subsonic',
          offset: 30,
          settings: {
            'server': 'http://x',
            'user': 'u',
            'password': 'p',
            'format': 'original',
          },
        ),
      );

      expect(routed.uris.first.queryParameters['songOffset'], '30');
    });

    test('Audiobookshelf asks for the page of the offset', () async {
      final routed = _RoutedDio({
        '/api/libraries': {
          'libraries': [
            {'id': 'lib', 'mediaType': 'book'},
          ],
        },
        '/items': {'results': <dynamic>[]},
      });

      await AudiobookshelfSourceAdapter(dio: routed.dio).scan(
        _request(
          'audiobookshelf',
          offset: 8,
          settings: {'server': 'http://x', 'token': 't'},
        ),
      );

      final items = routed.uris.firstWhere(
        (uri) => uri.path.endsWith('/items'),
      );
      expect(items.queryParameters['page'], '1');
    });

    test('a source without pages says so', () {
      expect(OpenverseSourceAdapter().supportsPaging, isTrue);
      expect(AudiusSourceAdapter().supportsPaging, isTrue);
      expect(InternetArchiveSourceAdapter().supportsPaging, isTrue);
      expect(LibrivoxSourceAdapter().supportsPaging, isTrue);
      expect(CcMixterSourceAdapter().supportsPaging, isTrue);
      expect(FunkwhaleSourceAdapter().supportsPaging, isTrue);
      expect(RadioSourceAdapter().supportsPaging, isTrue);
      expect(WikimediaSourceAdapter().supportsPaging, isTrue);
    });
  });
}

/// One scan of a source.
MusicSourceScanRequest _request(
  String id, {
  int offset = 0,
  Map<String, String> settings = const {},
}) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: id,
      type: id,
      name: id,
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
    offset: offset,
  );
}

/// A Dio that answers each request with the body of its route.
class _RoutedDio {
  _RoutedDio(this.routes);

  final Map<String, Object> routes;
  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          Object? body;
          for (final entry in routes.entries) {
            if (options.uri.path.contains(entry.key)) {
              body = entry.value;
              break;
            }
          }
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

/// A Dio that answers every request with one body and keeps the requests.
class _Captured {
  _Captured({required Object body}) : _body = body;

  final Object _body;
  final uris = <Uri>[];

  Uri? get uri => uris.isEmpty ? null : uris.last;

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          handler.resolve(
            Response(requestOptions: options, data: _body, statusCode: 200),
          );
        },
      ),
    );
    return client;
  }
}
