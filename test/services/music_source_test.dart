import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/ccmixter_source.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/itunes_source.dart';
import 'package:tune/data/services/music_sources/jamendo_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/netease_cloud_music_source.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
import 'package:tune/data/services/music_sources/podcast_rss_source.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
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

  group('source registry', () {
    test('built-in configs and adapters stay in sync', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      expect(
        service.adapters.map((adapter) => adapter.sourceType).toSet(),
        BuiltInMusicSources.defaults.map((source) => source.id).toSet(),
      );
      expect(service.supports('openverse'), isTrue);
      expect(service.supports('missing_source'), isFalse);
    });
  });

  group('source configuration schema', () {
    test('required fields match each adapter configuration check', () {
      final adapters = <MusicSourceAdapter>[
        OpenverseSourceAdapter(),
        JamendoSourceAdapter(),
        InternetArchiveSourceAdapter(),
        NeteaseCloudMusicSourceAdapter(),
        CcMixterSourceAdapter(),
        ITunesSourceAdapter(),
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

  group('Netease mapping', () {
    test('maps search songs and keeps artwork https', () {
      final songs = NeteaseCloudMusicSourceAdapter.parseSearchResults({
        'result': {
          'songs': [
            {
              'id': 123,
              'name': 'Song',
              'ar': [
                {'name': 'A'},
                {'name': 'B'},
              ],
              'al': {
                'name': 'Album',
                'picUrl': 'http://p1.music.126.net/a.jpg',
              },
              'dt': 240000,
            },
          ],
        },
      });

      expect(songs, hasLength(1));
      expect(songs.first.title, 'Song');
      expect(songs.first.artist, 'A / B');
      expect(songs.first.album, 'Album');
      expect(songs.first.duration, 240000);
      expect(songs.first.artworkUrl, startsWith('https://'));
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

