import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/audius_source.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/ccmixter_source.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/itunes_source.dart';
import 'package:tune/data/services/music_sources/jamendo_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
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

    test('the Internet Archive serves the audio everybody downloaded', () async {
      final captured = _Captured(body: {'response': {'docs': <dynamic>[]}});

      await InternetArchiveSourceAdapter(dio: captured.dio).scan(
        _request('internet_archive', const {}),
      );

      expect(captured.uri?.queryParameters['q'], 'mediatype:audio');
      expect(captured.uri?.queryParameters['sort[]'], 'downloads desc');
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

    test('Jamendo serves its charts', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await JamendoSourceAdapter(dio: captured.dio).scan(
        _request('jamendo', const {'clientId': 'demo'}),
      );

      expect(captured.uri?.queryParameters.containsKey('search'), isFalse);
      expect(captured.uri?.queryParameters['order'], 'popularity_total');
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

    test('a source without a browse stream still needs its keyword', () {
      final adapter = ITunesSourceAdapter();

      expect(
        adapter.isConfigured(_request('itunes', const {}).config),
        isFalse,
      );
      expect(
        adapter.isConfigured(
          _request('itunes', const {'query': 'jazz'}).config,
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

    test('a keyword the app wrote in another language is lost as well', () {
      final persistence = FakePersistenceService();
      persistence.values[MusicSourceStore.configsKey] = jsonEncode([
        {
          'id': 'netease',
          'name': 'Netease',
          'kind': 'openApi',
          'settings': {'keywords': 'trending'},
        },
      ]);

      final sources = MusicSourceStore(persistence).loadConfigs();
      final netease = sources.firstWhere((source) => source.id == 'netease');

      expect(netease.setting('keywords'), isNull);
    });
  });

  group('the form of a source', () {
    test('a source with a browse stream offers the streams it serves', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final fields = service.fieldsFor(
        MusicSourceConfig(
          id: 'audius:1',
          type: 'audius',
          name: 'Audius',
          kind: MusicSourceKind.openCatalog,
        ),
      );

      final browse = fields.firstWhere((field) => field.key == 'browse');
      expect(browse.choices.map((choice) => choice.value), [
        BrowseMode.charts,
      ]);
      expect(browse.label, isNotEmpty);
      expect(browse.hint, isNotEmpty);
    });

    test('a source without a browse stream asks for no stream', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final fields = service.fieldsFor(
        MusicSourceConfig(
          id: 'itunes:1',
          type: 'itunes',
          name: 'iTunes',
          kind: MusicSourceKind.openCatalog,
        ),
      );

      expect(fields.where((field) => field.key == 'browse'), isEmpty);
      expect(fields.firstWhere((field) => field.key == 'query').required, isTrue);
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
