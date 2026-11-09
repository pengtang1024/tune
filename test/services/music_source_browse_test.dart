import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/audius_source.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/ccmixter_source.dart';
import 'package:tune/data/services/music_sources/deezer_source.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/jamendo_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
import 'package:tune/data/services/music_sources/peertube_source.dart';
import 'package:tune/data/services/music_sources/wikimedia_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

import 'fake_persistence.dart';

/// A source that serves a list of its own needs no keyword.
///
/// The keyword stays a choice: an instance that names one searches with it,
/// and an instance that names none pulls the list the platform serves. The
/// tests below look at the request each source sends, because that is where
/// the two paths differ.
void main() {
  group('the browse streams of a source', () {
    test('Audius pulls the tracks everybody plays', () async {
      final captured = _Captured();

      final result = await AudiusSourceAdapter(dio: captured.dio).scan(
        _request('audius', const {}),
      );

      expect(captured.uri?.path, '/v1/tracks/trending');
      expect(result.status, SourceScanStatus.success);
    });

    test('Audius reads the playlists it ranks highest', () async {
      final answers = _AudiusPlaylists();

      final result = await AudiusSourceAdapter(dio: answers.dio).scan(
        _request('audius', const {
          'mode': 'playlists',
          'window': 'week',
          'limit': '4',
        }),
      );

      expect(answers.uris.first.path, '/v1/playlists/trending');
      expect(answers.uris.first.queryParameters['time'], 'week');
      expect(answers.uris.last.path, '/v1/playlists/pl-1/tracks');
      // A playlist holds dozens of tracks; the scan keeps the window.
      expect(result.songs, hasLength(4));
    });

    test('the reader decides how many playlists one scan reads', () async {
      final answers = _AudiusPlaylists();

      await AudiusSourceAdapter(dio: answers.dio).scan(
        _request('audius', const {'mode': 'playlists', 'playlists': '2'}),
      );

      expect(answers.uris.first.queryParameters['limit'], '2');
      expect(answers.uris.first.path, '/v1/playlists/trending');
    });
    test('a keyword reads the playlists it is found in', () async {
      final answers = _AudiusPlaylists();

      await AudiusSourceAdapter(dio: answers.dio).scan(
        _request('audius', const {'mode': 'playlists', 'query': 'lo-fi'}),
      );

      expect(answers.uris.first.path, '/v1/playlists/search');
      expect(answers.uris.first.queryParameters['query'], 'lo-fi');
    });

    test('Audius searches when the reader names a keyword', () async {
      final captured = _Captured();

      await AudiusSourceAdapter(dio: captured.dio).scan(
        _request('audius', const {'query': 'ambient'}),
      );

      expect(captured.uri?.path, '/v1/tracks/search');
      expect(captured.uri?.queryParameters['query'], 'ambient');
    });

    test('ccMixter asks for its charts', () async {
      final captured = _Captured(body: '[]');

      await CcMixterSourceAdapter(dio: captured.dio).scan(
        _request('ccmixter', const {}),
      );

      expect(captured.uri?.queryParameters.containsKey('tags'), isFalse);
      expect(captured.uri?.queryParameters['sort'], 'rank');
    });

    test('ccMixter asks for its newest uploads', () async {
      final captured = _Captured(body: '[]');

      await CcMixterSourceAdapter(dio: captured.dio).scan(
        _request('ccmixter', const {'browse': BrowseMode.latest}),
      );

      expect(captured.uri?.queryParameters.containsKey('tags'), isFalse);
      expect(captured.uri?.queryParameters.containsKey('sort'), isFalse);
    });

    test('ccMixter narrows the site by a genre', () async {
      final captured = _Captured(body: '[]');

      await CcMixterSourceAdapter(dio: captured.dio).scan(
        _request('ccmixter', const {'tag': 'jazz'}),
      );

      expect(captured.uri?.queryParameters['tags'], 'jazz');
    });

    test('a keyword and a genre narrow together', () async {
      final captured = _Captured(body: '[]');

      await CcMixterSourceAdapter(dio: captured.dio).scan(
        _request('ccmixter', const {'query': 'piano', 'tag': 'jazz'}),
      );

      // The site reads several tags as one word: both must match.
      expect(captured.uri?.queryParameters['tags'], 'piano,jazz');
    });

    test('the Internet Archive serves the audio everybody downloaded', () async {
      final captured = _Captured(body: {'response': {'docs': <dynamic>[]}});

      await InternetArchiveSourceAdapter(dio: captured.dio).scan(
        _request('internet_archive', const {}),
      );

      expect(captured.uri?.queryParameters['q'], 'mediatype:audio');
      expect(captured.uri?.queryParameters['sort[]'], 'downloads desc');
    });

    test('the Internet Archive serves the audio published last', () async {
      final captured = _Captured(body: {'response': {'docs': <dynamic>[]}});

      await InternetArchiveSourceAdapter(dio: captured.dio).scan(
        _request('internet_archive', const {'browse': BrowseMode.latest}),
      );

      expect(captured.uri?.queryParameters['sort[]'], 'publicdate desc');
    });

    test('Openverse serves the audio it published last', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await OpenverseSourceAdapter(dio: captured.dio).scan(
        _request('openverse', const {}),
      );

      expect(captured.uri?.queryParameters.containsKey('q'), isFalse);
    });

    test('Wikimedia walks a category of the wiki', () async {
      final captured = _Captured(body: {'query': {'pages': <String, dynamic>{}}});

      await WikimediaSourceAdapter(dio: captured.dio).scan(
        _request('wikimedia', const {}),
      );

      expect(captured.uri?.queryParameters['generator'], 'categorymembers');
      expect(captured.uri?.queryParameters['gcmtype'], 'file');
      expect(captured.uri?.queryParameters['gcmtitle'], isNotEmpty);
    });

    test('Wikimedia walks the category the reader picked', () async {
      final captured = _Captured(body: {'query': {'pages': <String, dynamic>{}}});

      await WikimediaSourceAdapter(dio: captured.dio).scan(
        _request('wikimedia', const {'category': 'jazz'}),
      );

      expect(
        captured.uri?.queryParameters['gcmtitle'],
        'Category:Audio files of jazz music',
      );
    });

    test('a genre of the commons is walked by its own name', () async {
      final captured = _Captured(body: {'query': {'pages': <String, dynamic>{}}});

      await WikimediaSourceAdapter(dio: captured.dio).scan(
        _request('wikimedia', const {'category': 'dnb'}),
      );

      expect(
        captured.uri?.queryParameters['gcmtitle'],
        'Category:Audio files of drum and bass',
      );
    });

    test('Wikimedia walks a category the reader picked from the newer ones', () async {
      final captured = _Captured(body: {'query': {'pages': <String, dynamic>{}}});

      await WikimediaSourceAdapter(dio: captured.dio).scan(
        _request('wikimedia', const {'category': 'reggae'}),
      );

      expect(
        captured.uri?.queryParameters['gcmtitle'],
        'Category:Audio files of reggae',
      );
    });

    test('a category named by the commons itself is walked as written', () async {
      final captured = _Captured(body: {'query': {'pages': <String, dynamic>{}}});

      await WikimediaSourceAdapter(dio: captured.dio).scan(
        _request('wikimedia', const {'category': 'spoken'}),
      );

      // Spoken articles are not filed under "Audio files of ...", so the
      // name of the category is not built from the reach.
      expect(
        captured.uri?.queryParameters['gcmtitle'],
        'Category:Spoken Wikipedia',
      );
    });

    test('a category the commons does not file falls back to all music', () async {
      final captured = _Captured(body: {'query': {'pages': <String, dynamic>{}}});

      await WikimediaSourceAdapter(dio: captured.dio).scan(
        _request('wikimedia', const {'category': 'soul'}),
      );

      // Soul is not filed by the commons, and an empty category answers
      // nothing at all; the whole of the music is read instead.
      expect(
        captured.uri?.queryParameters['gcmtitle'],
        'Category:Audio files of music',
      );
    });
    test('Wikimedia walks the whole music of the wiki by default', () async {
      final captured = _Captured(body: {'query': {'pages': <String, dynamic>{}}});

      await WikimediaSourceAdapter(dio: captured.dio).scan(
        _request('wikimedia', const {}),
      );

      expect(
        captured.uri?.queryParameters['gcmtitle'],
        'Category:Audio files of music',
      );
    });

    test('a keyword still searches the wiki, whatever the category', () async {
      final captured = _Captured(body: {'query': {'pages': <String, dynamic>{}}});

      await WikimediaSourceAdapter(dio: captured.dio).scan(
        _request('wikimedia', const {'category': 'jazz', 'query': 'piano'}),
      );

      expect(captured.uri?.queryParameters['generator'], 'search');
      expect(captured.uri?.queryParameters.containsKey('gcmtitle'), isFalse);
    });

    test('a sort the reader picked is asked for', () async {
      final captured = _Captured(body: {'data': <dynamic>[]});

      await PeerTubeSourceAdapter(dio: captured.dio).scan(
        _request('peertube', const {
          'server': 'https://framatube.org',
          'query': 'jazz',
          'sort': '-publishedAt',
        }),
      );

      expect(captured.uri?.queryParameters['sort'], '-publishedAt');
      expect(captured.uri?.path, '/api/v1/search/videos');
    });

    test('a video is filed under its tags and its tongue', () async {
      final captured = _CapturedRoutes({
        '/api/v1/videos': jsonEncode({
          'data': [
            {
              'uuid': 'v-1',
              'name': 'A song',
              'category': {'id': 1, 'label': 'Music'},
              'language': {'id': 'de', 'label': 'German'},
              'tags': ['chant', 'musique', 'chant'],
              'duration': 180,
              'files': [
                {'fileUrl': 'https://tube.example/download/v-1.mp4'},
              ],
            },
            {
              'uuid': 'v-2',
              'name': 'No tags',
              'category': {'id': 1, 'label': 'Music'},
              'language': {'id': 'zxx', 'label': 'Unknown'},
              'tags': <dynamic>[],
              'duration': 120,
              'files': [
                {'fileUrl': 'https://tube.example/download/v-2.mp4'},
              ],
            },
          ],
        }),
        '/api/v1/videos/v-1': jsonEncode({
          'uuid': 'v-1',
          'name': 'A song',
          'category': {'id': 1, 'label': 'Music'},
          'language': {'id': 'de', 'label': 'German'},
          'tags': ['chant', 'musique', 'chant'],
          'duration': 180,
          'files': [
            {'fileUrl': 'https://tube.example/download/v-1.mp4'},
          ],
        }),
        '/api/v1/videos/v-2': jsonEncode({
          'uuid': 'v-2',
          'name': 'No tags',
          'category': {'id': 1, 'label': 'Music'},
          'language': {'id': 'zxx', 'label': 'Unknown'},
          'tags': <dynamic>[],
          'duration': 120,
          'files': [
            {'fileUrl': 'https://tube.example/download/v-2.mp4'},
          ],
        }),
      });

      final result = await PeerTubeSourceAdapter(dio: captured.dio).scan(
        _request('peertube', const {'server': 'https://tube.example', 'limit': '5'}),
      );

      final tagged = result.songs.first;
      expect(tagged.genre, 'chant');
      expect(tagged.genres, ['chant', 'musique']);
      expect(tagged.language, 'German');

      // A video without tags keeps its category; an unknown tongue is none.
      final untagged = result.songs.last;
      expect(untagged.genre, 'Music');
      expect(untagged.language, isNull);
    });
    test('a search without a chosen sort keeps the order of the server', () async {
      final captured = _Captured(body: {'data': <dynamic>[]});

      await PeerTubeSourceAdapter(dio: captured.dio).scan(
        _request('peertube', const {
          'server': 'https://framatube.org',
          'query': 'jazz',
        }),
      );

      expect(captured.uri?.queryParameters.containsKey('sort'), isFalse);
    });

    test('a chosen sort takes precedence over the browsing mode', () async {
      final captured = _Captured(body: {'data': <dynamic>[]});

      await PeerTubeSourceAdapter(dio: captured.dio).scan(
        _request('peertube', const {
          'server': 'https://framatube.org',
          'sort': '-views',
        }),
      );

      expect(captured.uri?.path, '/api/v1/videos');
      expect(captured.uri?.queryParameters['sort'], '-views');
    });
    test('Jamendo serves its charts', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await JamendoSourceAdapter(dio: captured.dio).scan(
        _request('jamendo', const {'clientId': 'demo'}),
      );

      expect(captured.uri?.queryParameters.containsKey('search'), isFalse);
      expect(captured.uri?.queryParameters['order'], 'popularity_total');
    });

    test('the nichest reaches of the archive ship folded away', () {
      final catalogue = BuiltInMusicSources.catalogueOf(AppStrings.instance);

      for (final id in const [
        'internet_archive',
        'news_recordings',
        'poetry',
        'poetry_books',
        'science_talks',
      ]) {
        final source = catalogue[id];
        expect(source, isNotNull, reason: id);
        // The folded group of the source list starts below 500.
        expect(source!.weight, lessThan(500), reason: id);
      }
    });
    test('a licence narrows the uploads', () async {
      final captured = _Captured(body: '[]');

      await CcMixterSourceAdapter(dio: captured.dio).scan(
        _request('ccmixter', const {'licence': 'pd'}),
      );

      expect(captured.uri?.queryParameters['lic'], 'pd');
    });

    test('a licence the site does not know is not sent', () async {
      final captured = _Captured(body: '[]');

      await CcMixterSourceAdapter(dio: captured.dio).scan(
        _request('ccmixter', const {'licence': 'by-sa'}),
      );

      // The site answers a word it cannot read with an error, not a list.
      expect(captured.uri?.queryParameters.containsKey('lic'), isFalse);
    });
    test('a sort the reader picks is passed to the archive', () async {
      final captured = _CapturedArchive();

      await InternetArchiveSourceAdapter(dio: captured.dio).scan(
        _request('internet_archive', const {'sort': 'published'}),
      );

      expect(captured.query?['sort[]'], 'publicdate desc');
    });
    test('the classical list is kept apart from the four community styles', () {
      // Both list the same uploads; the second one excludes the first's
      // styles so one recording does not arrive through both.
      final instance = BuiltInMusicSources.communityClassical;
      expect(instance.setting('query'), contains('subject:(classical)'));
      expect(instance.setting('query'), contains('NOT'));
      expect(instance.weight, 400);
    });

    test('the ambient list excludes the five styles already offered', () {
      final instance = BuiltInMusicSources.communityAmbient;
      final query = instance.setting('query') ?? '';
      expect(query, contains('subject:(ambient OR experimental)'));
      expect(query, contains('classical'));
      expect(instance.weight, 400);
    });

    test('the world list excludes every other community style', () {
      final query = BuiltInMusicSources.communityWorld.setting('query') ?? '';
      expect(query, contains('subject:(world OR reggae)'));
      expect(query, contains('ambient OR experimental'));
      expect(BuiltInMusicSources.communityWorld.weight, 400);
    });

    test('the metal list excludes every other community style', () {
      final query = BuiltInMusicSources.communityMetal.setting('query') ?? '';
      expect(query, contains('subject:(metal OR punk)'));
      expect(query, contains('world OR reggae'));
      expect(BuiltInMusicSources.communityMetal.weight, 400);
    });

    test('the hip-hop list excludes every other community style', () {
      final query = BuiltInMusicSources.communityHiphop.setting('query') ?? '';
      expect(query, contains('subject:(hiphop OR funk)'));
      expect(query, contains('metal OR punk'));
      expect(BuiltInMusicSources.communityHiphop.weight, 400);
    });

    test('every source opens with the stream the app intends', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );
      // The stream a source opens with is what a reader sees first, so it is
      // pinned here: a change of it has to be a change of this list too.
      const expected = {
        'internet_archive': 'charts',
        'librivox': 'charts',
        'audius': 'charts',
        'ccmixter': 'charts',
        'deezer': 'charts',
        'kodi': 'latest',
        'audiobookshelf': 'latest',
        'funkwhale': 'latest',
      };

      for (final source in BuiltInMusicSources.defaults) {
        final adapter = service.adapters.firstWhere(
          (adapter) => adapter.sourceType == source.sourceType,
        );
        if (adapter.browseModes.isEmpty) continue;
        final mode = adapter.browseModeOf(source);
        expect(adapter.browseModes, contains(mode), reason: source.id);
        final pinned = expected[source.sourceType];
        if (pinned != null) {
          expect(mode, pinned, reason: '${source.id} (${source.sourceType})');
        }
      }
    });
    test('a window of dates is asked of the archive itself', () async {
      final captured = _CapturedArchive();

      await InternetArchiveSourceAdapter(dio: captured.dio).scan(
        _request('internet_archive', const {'since': '30'}),
      );

      // The archive leaves the older items out; the app never sees them.
      expect(captured.query?['q'], contains('addeddate:['));
    });

    test('a window the app does not offer is not sent', () async {
      final captured = _CapturedArchive();

      await InternetArchiveSourceAdapter(dio: captured.dio).scan(
        _request('internet_archive', const {'since': '45'}),
      );

      expect(captured.query?['q'], isNot(contains('addeddate:')));
    });
    test('the reader decides how many albums one scan reads', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await DeezerSourceAdapter(dio: captured.dio).scan(
        _request('deezer', const {'mode': 'albums', 'query': 'jazz', 'batch': '1'}),
      );

      // An album is read whole, so the batch sizes the chart it walks.
      expect(captured.uri?.queryParameters['limit'], '1');
    });
    test('Jamendo narrows the catalogue by a tag', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await JamendoSourceAdapter(dio: captured.dio).scan(
        _request('jamendo', const {'clientId': 'demo', 'tag': 'jazz'}),
      );

      expect(captured.uri?.queryParameters['tags'], 'jazz');
    });

    test('Jamendo asks for no tag when none is written', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await JamendoSourceAdapter(dio: captured.dio).scan(
        _request('jamendo', const {'clientId': 'demo'}),
      );

      expect(captured.uri?.queryParameters.containsKey('tags'), isFalse);
    });
    test('Jamendo serves its newest releases', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await JamendoSourceAdapter(dio: captured.dio).scan(
        _request('jamendo', const {
          'clientId': 'demo',
          'browse': BrowseMode.latest,
        }),
      );

      expect(captured.uri?.queryParameters['order'], 'release_date');
    });
  });

  group('a browse stream means the source is ready', () {
    test('a source with a browse stream needs no keyword', () {
      expect(
        AudiusSourceAdapter().isConfigured(_request('audius', const {}).config),
        isTrue,
      );
      expect(
        CcMixterSourceAdapter().isConfigured(
          _request('ccmixter', const {}).config,
        ),
        isTrue,
      );
    });

    test('a source that asks for no key is ready without a keyword', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      for (final type in ['audius', 'ccmixter', 'internet_archive', 'openverse', 'wikimedia']) {
        expect(
          service.isConfigured(
            MusicSourceConfig(
              id: type,
              type: type,
              name: type,
              kind: MusicSourceKind.openCatalog,
            ),
          ),
          isTrue,
          reason: '$type serves a list of its own',
        );
      }
    });

    test('a source that asks for a key still asks for the key', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      expect(
        service.isConfigured(
          MusicSourceConfig(
            id: 'jamendo',
            type: 'jamendo',
            name: 'Jamendo',
            kind: MusicSourceKind.openCatalog,
          ),
        ),
        isFalse,
        reason: 'Jamendo serves its charts, but only with a key',
      );
    });
  });

  group('the keyword the app used to write', () {
    test('an instance nobody touched loses it', () {
      final persistence = FakePersistenceService();
      persistence.values[MusicSourceStore.configsKey] = jsonEncode([
        {
          'id': 'openverse',
          'name': 'Openverse',
          'kind': 'openCatalog',
          'settings': {'query': 'piano'},
        },
      ]);

      final sources = MusicSourceStore(persistence).loadConfigs();
      final openverse = sources.firstWhere((source) => source.id == 'openverse');

      expect(openverse.setting('query'), isNull);
    });

    test('an instance the reader changed keeps its keyword', () {
      final persistence = FakePersistenceService();
      persistence.values[MusicSourceStore.configsKey] = jsonEncode([
        {
          'id': 'openverse',
          'name': 'Openverse',
          'kind': 'openCatalog',
          'settings': {'query': 'piano', 'limit': '30'},
        },
      ]);

      final sources = MusicSourceStore(persistence).loadConfigs();
      final openverse = sources.firstWhere((source) => source.id == 'openverse');

      expect(openverse.setting('query'), 'piano');
    });

    test('the names of the streams are written in the language of the app', () {
      final chinese = AppStrings.of(const Locale('zh', 'CN'));
      final english = AppStrings.of(const Locale('en'));

      expect(BrowseMode.labelOf(BrowseMode.charts, chinese), '排行');
      expect(BrowseMode.labelOf(BrowseMode.charts, english), 'Charts');
      expect(BrowseMode.labelOf(BrowseMode.latest, chinese), '最新');
      expect(BrowseMode.labelOf(BrowseMode.daily, chinese), '每日推荐');
    });
  });
}

/// A request of one source instance.
MusicSourceScanRequest _request(String sourceId, Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: sourceId,
      type: sourceId,
      name: sourceId,
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
  );
}

/// A Dio that answers every request with the same body and remembers where
/// the request went.

/// Answers the playlist calls of Audius: one playlist, six tracks.
class _AudiusPlaylists {
  _AudiusPlaylists();

  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          final path = options.uri.path;
          final Object body;
          if (path == '/v1/playlists/trending' || path == '/v1/playlists/search') {
            body = {
              'data': [
                {'id': 'pl-1', 'playlist_name': 'One'},
              ],
            };
          } else {
            body = {
              'data': [
                for (var index = 1; index <= 6; index++)
                  {
                    'id': 'trk-$index',
                    'title': 'Track $index',
                    'user': {'name': 'Someone'},
                  },
              ],
            };
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

class _Captured {
  _Captured({Object? body}) : _body = body ?? {'data': <dynamic>[]};

  final Object _body;
  Uri? uri;

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uri = options.uri;
          handler.resolve(
            Response(
              requestOptions: options,
              data: _body,
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}

/// A Dio that answers the archive with an empty page and keeps the query.
class _CapturedArchive {
  Map<String, dynamic>? query;

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          query = options.uri.queryParameters;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'response': {'numFound': 0, 'docs': <dynamic>[]},
              },
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}

/// A Dio that answers each path of a PeerTube instance with its own body.
class _CapturedRoutes {
  _CapturedRoutes(this.bodies);

  final Map<String, String> bodies;

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final body = bodies[options.uri.path];
          handler.resolve(
            Response(
              requestOptions: options,
              data: body ?? '{}',
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}
