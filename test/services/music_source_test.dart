import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/ccmixter_source.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/jamendo_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
import 'package:tune/data/services/music_sources/podcast_rss_source.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/data/services/music_sources/subsonic_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';

import 'fake_persistence.dart';

void main() {
  group('Song source fields', () {
    test('remote fields survive JSON round-trip', () {
      const song = Song(
        id: 7,
        title: 'Piano',
        artist: 'benpm',
        album: 'Set',
        duration: 10193,
        uri: 'tune://openverse/abc',
        sourceId: 'openverse',
        externalId: 'abc',
        streamUrl: 'https://example.com/a.mp3',
        artworkUrl: 'https://example.com/a.jpg',
        sourceData: {'id': 'abc', 'custom': 42},
        httpHeaders: {'Referer': 'https://example.com'},
      );

      final restored = Song.fromMap(song.toJson());

      expect(restored.sourceId, 'openverse');
      expect(restored.externalId, 'abc');
      expect(restored.streamUrl, 'https://example.com/a.mp3');
      expect(restored.artworkUrl, 'https://example.com/a.jpg');
      expect(restored.sourceData?['custom'], 42);
      expect(restored.httpHeaders?['Referer'], 'https://example.com');
      expect(restored.playbackUri, 'https://example.com/a.mp3');
    });

    test('local songs keep using uri for playback', () {
      const song = Song(id: 1, title: 'Local', uri: '/music/a.mp3');
      expect(song.playbackUri, '/music/a.mp3');
    });
  });

  group('SourceSongFactory', () {
    test('stable ids are deterministic and source-specific', () {
      final first = SourceSongFactory.stableId('tune://openverse/abc');
      final second = SourceSongFactory.stableId('tune://openverse/abc');
      final different = SourceSongFactory.stableId('tune://jamendo/abc');

      expect(first, second);
      expect(first, isNot(different));
      expect(first, greaterThan(0));
    });

    test('only http(s) urls are accepted', () {
      expect(SourceSongFactory.normalizeUrl('https://a.test/a.mp3'), isNotNull);
      expect(SourceSongFactory.normalizeUrl('http://a.test/a.mp3'), isNotNull);
      expect(SourceSongFactory.normalizeUrl('file:///a.mp3'), isNull);
      expect(SourceSongFactory.normalizeUrl(''), isNull);
    });
  });

  group('scanning a library', () {
    test('a search reads the sources a few at a time too', () async {
      final adapter = _CountingAdapter();
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
        adapters: {'counting': adapter},
      );
      final sources = [
        for (var index = 0; index < 20; index++)
          MusicSourceConfig(
            id: 's$index',
            type: 'counting',
            name: 'Source $index',
            kind: MusicSourceKind.openCatalog,
          ),
      ];

      final results = await service.search(sources: sources, query: 'jazz');

      expect(results, hasLength(20));
      expect(results.map((result) => result.sourceId), [
        for (var index = 0; index < 20; index++) 's$index',
      ]);
      expect(adapter.peak, lessThanOrEqualTo(MusicSourceService.maxConcurrentScans));
      expect(adapter.peak, greaterThan(1));
    });
    test('the sources are read a few at a time', () async {
      final adapter = _CountingAdapter();
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
        adapters: {'counting': adapter},
      );
      final sources = [
        for (var index = 0; index < 20; index++)
          MusicSourceConfig(
            id: 's$index',
            type: 'counting',
            name: 'Source $index',
            kind: MusicSourceKind.openCatalog,
          ),
      ];

      final results = await service.scanAll(
        sources: sources,
        localPaths: const [],
      );

      expect(results, hasLength(20));
      // The answers keep the order of the sources, not of the finishes.
      expect(results.map((result) => result.sourceId), [
        for (var index = 0; index < 20; index++) 's$index',
      ]);
      // Never more than the app allows at once, and more than one at all.
      expect(adapter.peak, lessThanOrEqualTo(MusicSourceService.maxConcurrentScans));
      expect(adapter.peak, greaterThan(1));
    });
  });

  group('source registry', () {
    test('built-in configs and adapters stay in sync', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // Every built-in instance is served by an adapter. A type the reader
      // adds comes without an instance, so the two are not the same set.
      final builtIn = BuiltInMusicSources.defaults;
      for (final source in builtIn) {
        expect(
          service.supports(source.sourceType),
          isTrue,
          reason: '${source.sourceType} has no adapter',
        );
      }
      expect(
        service.adapters.map((adapter) => adapter.sourceType).toSet(),
        containsAll(builtIn.map((source) => source.sourceType).toSet()),
      );
      expect(service.supports('openverse'), isTrue);
      expect(service.supports('missing_source'), isFalse);
    });
  });

  group('source settings migration', () {
    test('the old keyword of one instance goes, a new one keeps its query', () {
      final persistence = FakePersistenceService();
      persistence.values[MusicSourceStore.configsKey] = jsonEncode([
        {
          'id': 'internet_archive',
          'type': 'internet_archive',
          'name': 'Internet Archive',
          'settings': {'query': 'collection:netlabels AND mediatype:audio'},
        },
        {
          'id': 'live_music_archive',
          'type': 'internet_archive',
          'name': 'Live Music Archive',
          'settings': {'query': 'collection:etree'},
        },
        {
          'id': 'netlabels',
          'type': 'internet_archive',
          'name': 'Netlabels',
          'settings': {'query': 'collection:netlabels AND mediatype:audio'},
        },
      ]);

      final byId = {
        for (final config in MusicSourceStore(persistence).loadConfigs())
          config.id: config,
      };

      // The original instance never had a keyword of its own: the old default
      // goes, so the platform's own list takes its place.
      expect(byId['internet_archive']!.settings['query'], isNull);
      // The two instances keep their own collections; the retired value of a
      // neighbour does not touch them.
      expect(
        byId['live_music_archive']!.settings['query'],
        'collection:etree AND mediatype:etree',
      );
      expect(
        byId['netlabels']!.settings['query'],
        'collection:netlabels AND mediatype:audio',
      );
    });
  });

  group('source configuration schema', () {
    test('required fields match each adapter configuration check', () {
      final adapters = <MusicSourceAdapter>[
        OpenverseSourceAdapter(),
        JamendoSourceAdapter(),
        InternetArchiveSourceAdapter(),
        CcMixterSourceAdapter(),
        PodcastRssSourceAdapter(),
        SubsonicSourceAdapter(),
      ];

      for (final adapter in adapters) {
        final empty = MusicSourceConfig(
          id: adapter.sourceType,
          name: adapter.sourceType,
          kind: MusicSourceKind.openApi,
        );
        final required = adapter.configurationFields
            .where((field) => field.required)
            .toList(growable: false);

        expect(
          adapter.isConfigured(empty),
          required.isEmpty,
          reason: adapter.sourceType,
        );

        if (required.isEmpty) continue;

        final filled = empty.copyWith(
          settings: {
            for (final field in required)
              field.key: field.numeric ? '1' : 'value',
          },
        );
        expect(adapter.isConfigured(filled), isTrue, reason: adapter.sourceType);
      }
    });
  });

  group('Openverse mapping', () {
    test('maps openverse results and skips entries without a stream', () {
      final songs = OpenverseSourceAdapter.parseResults({
        'results': [
          {
            'id': 'abc',
            'title': 'Piano Melody',
            'creator': 'benpm',
            'url': 'https://cdn.example.com/a.mp3',
            'duration': 10193,
            'thumbnail': 'https://cdn.example.com/a.jpg',
            'audio_set': {'title': 'Piano Set'},
            'genres': ['classical'],
            'provider': 'freesound',
          },
          {'id': 'empty', 'title': 'No URL', 'url': null},
        ],
      }, sourceId: 'openverse');

      expect(songs, hasLength(1));
      expect(songs.first.title, 'Piano Melody');
      expect(songs.first.artist, 'benpm');
      expect(songs.first.album, 'Piano Set');
      expect(songs.first.duration, 10193);
      expect(songs.first.genre, 'classical');
      expect(songs.first.sourceId, 'openverse');
      expect(songs.first.playbackUri, 'https://cdn.example.com/a.mp3');
    });
  });

  group('Jamendo mapping', () {
    test('maps results and converts seconds to milliseconds', () {
      final songs = JamendoSourceAdapter.parseResults({
        'results': [
          {
            'id': '42',
            'name': 'Night Drive',
            'artist_name': 'Artist',
            'album_name': 'Album',
            'duration': 180,
            'audio': 'https://prod.jamendo.com/?trackid=42&format=mp32',
            'image': 'https://img.jamendo.com/42.jpg',
            'releasedate': '2020-05-01',
            'musicinfo': {
              'tags': {
                'genres': ['electronic'],
              },
            },
          },
        ],
      }, sourceId: 'jamendo');

      expect(songs, hasLength(1));
      expect(songs.first.title, 'Night Drive');
      expect(songs.first.album, 'Album');
      expect(songs.first.duration, 180000);
      expect(songs.first.genre, 'electronic');
      expect(songs.first.year, 2020);
    });
  });

  group('MusicSourceStore', () {
    test('merges saved settings over built-in defaults', () async {
      final persistence = FakePersistenceService();
      final store = MusicSourceStore(persistence);

      final defaults = store.loadConfigs();
      final openverse = defaults.firstWhere(
        (source) => source.id == 'openverse',
      );
      expect(openverse.enabled, isTrue);

      await store.saveConfigs([
        for (final source in defaults)
          if (source.id == 'openverse')
            source.copyWith(enabled: false, settings: {'query': 'jazz'})
          else
            source,
      ]);

      final reloaded = store.loadConfigs();
      final saved = reloaded.firstWhere((source) => source.id == 'openverse');
      expect(saved.enabled, isFalse);
      expect(saved.setting('query'), 'jazz');
    });

    test('persists last scan timestamps', () async {
      final store = MusicSourceStore(FakePersistenceService());
      expect(store.lastScanAt('openverse'), isNull);

      final now = DateTime(2026, 10, 19, 12, 30);
      await store.markScanned('openverse', now);

      expect(store.lastScanAt('openverse'), now);
    });

    test('parallel scans keep every timestamp', () async {
      final persistence = FakePersistenceService();
      final store = MusicSourceStore(persistence);
      final openverse = DateTime(2026, 10, 19, 12, 30);
      final jamendo = DateTime(2026, 10, 19, 12, 31);

      await Future.wait([
        store.markScanned('openverse', openverse),
        store.markScanned('jamendo', jamendo),
      ]);

      final reloaded = MusicSourceStore(persistence);
      expect(reloaded.lastScanAt('openverse'), openverse);
      expect(reloaded.lastScanAt('jamendo'), jamendo);
    });
  });

  group('MusicSourceConfig', () {
    test('round-trips through JSON', () {
      const config = MusicSourceConfig(
        id: 'custom',
        name: 'Custom',
        description: 'Custom API',
        kind: MusicSourceKind.openApi,
        enabled: false,
        settings: {'baseUrl': 'http://localhost:3000'},
      );

      final restored = MusicSourceConfig.fromJson(config.toJson());
      expect(restored.id, 'custom');
      expect(restored.kind, MusicSourceKind.openApi);
      expect(restored.enabled, isFalse);
      expect(restored.setting('baseUrl'), 'http://localhost:3000');
    });

    test('malformed enabled values fall back to enabled', () {
      final restored = MusicSourceConfig.fromJson({
        'id': 'custom',
        'kind': 'openApi',
        'enabled': 'yes',
      });

      expect(restored.enabled, isTrue);
    });
  });
}

/// An adapter that counts how many of its scans run at the same time.
class _CountingAdapter extends MusicSourceAdapter {
  int _running = 0;
  int peak = 0;

  @override
  String get sourceType => 'counting';

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => 'Counting';

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    _running++;
    if (_running > peak) peak = _running;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _running--;
    return SourceScanResult(
      sourceId: request.config.id,
      status: SourceScanStatus.success,
      songs: const [],
    );
  }
}
