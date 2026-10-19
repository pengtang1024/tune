import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/lrclib_lyrics_provider.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/netease_cloud_music_source.dart';
import 'package:tune/data/services/music_sources/subsonic_source.dart';
import 'package:tune/domain/models/song.dart';

import 'fake_persistence.dart';

void main() {
  group('LRCLIB provider', () {
    test('prefers a sheet with time stamps of the same length', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {
          'duration': 400,
          'plainLyrics': 'plain of another length',
          'syncedLyrics': '[00:10] synced of another length',
        },
        {
          'duration': 100,
          'plainLyrics': 'plain of the same length',
          'syncedLyrics': '[00:10] synced of the same length',
        },
      ], 100000);

      expect(picked, '[00:10] synced of the same length');
    });

    test('prefers the plain text of the same length over a foreign sheet', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {'duration': 400, 'syncedLyrics': '[00:10] synced of another length'},
        {'duration': 100, 'plainLyrics': 'plain of the same length'},
      ], 100000);

      expect(picked, 'plain of the same length');
    });

    test('falls back to a sheet of another length', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {
          'duration': 400,
          'plainLyrics': 'plain of another length',
          'syncedLyrics': '[00:10] synced of another length',
        },
      ], 100000);

      expect(picked, '[00:10] synced of another length');
    });

    test('ignores an empty text', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {'duration': 100, 'plainLyrics': '   ', 'syncedLyrics': ''},
      ], 100000);

      expect(picked, isNull);
    });

    test('answers an empty answer with no sheet', () {
      expect(LrclibLyricsProvider.pickLyrics(const [], 100000), isNull);
      expect(LrclibLyricsProvider.pickLyrics(['not a map'], 100000), isNull);
    });
  });

  group('Netease lyrics', () {
    test('prefers the timed sheet', () {
      final lyrics = NeteaseCloudMusicSourceAdapter.parseLyrics({
        'lrc': {'lyric': '[00:00] plain'},
        'tlyric': {'lyric': '[00:00] timed'},
      });

      expect(lyrics, '[00:00] timed');
    });

    test('falls back to the plain text', () {
      final lyrics = NeteaseCloudMusicSourceAdapter.parseLyrics({
        'lrc': {'lyric': '  [00:00] plain  '},
      });

      expect(lyrics, '[00:00] plain');
    });

    test('answers an empty answer with no text', () {
      expect(NeteaseCloudMusicSourceAdapter.parseLyrics(const {}), isNull);
      expect(
        NeteaseCloudMusicSourceAdapter.parseLyrics({
          'lrc': {'lyric': ' '},
        }),
        isNull,
      );
    });
  });

  group('Subsonic lyrics', () {
    test('reads the text of the track', () {
      final lyrics = SubsonicSourceAdapter.parseLyrics({
        'lyrics': {
          'song': {'value': '  first line\nsecond line  '},
        },
      });

      expect(lyrics, 'first line\nsecond line');
    });

    test('answers an empty answer with no text', () {
      expect(SubsonicSourceAdapter.parseLyrics(const {}), isNull);
      expect(
        SubsonicSourceAdapter.parseLyrics({
          'lyrics': {
            'song': {'value': ' '},
          },
        }),
        isNull,
      );
    });
  });

  group('lyrics of the service', () {
    test('a track that carries lyrics keeps them', () async {
      final provider = _RecordingLyricsProvider('from the database');
      final service = _service(provider);

      final lyrics = await service.fetchLyrics(
        const Song(
          id: 1,
          title: 'Night Drive',
          artist: 'Nova',
          uri: 'tune://openverse/1',
          sourceId: 'openverse',
          externalId: '1',
          lyrics: 'already there',
        ),
      );

      expect(lyrics, 'already there');
      expect(provider.asked, isEmpty);
    });

    test('a source without lyrics falls back to the database', () async {
      final provider = _RecordingLyricsProvider('from the database');
      final service = _service(provider);

      final lyrics = await service.fetchLyrics(
        const Song(
          id: 2,
          title: 'Night Drive',
          artist: 'Nova',
          uri: 'tune://openverse/2',
          sourceId: 'openverse',
          externalId: '2',
        ),
      );

      expect(lyrics, 'from the database');
      expect(provider.asked, hasLength(1));
      expect(provider.asked.single.title, 'Night Drive');
    });

    test('a track without a source has no lyrics', () async {
      final provider = _RecordingLyricsProvider('from the database');
      final service = _service(provider);

      final lyrics = await service.fetchLyrics(
        const Song(
          id: 3,
          title: 'Night Drive',
          artist: 'Nova',
          uri: '/music/local.mp3',
        ),
      );

      expect(lyrics, isNull);
      expect(provider.asked, isEmpty);
    });
  });
}

/// The service under test, backed by an in-memory store.
MusicSourceService _service(LyricsProvider provider) {
  return MusicSourceService(
    scanner: CrossPlatformMusicScannerImpl(),
    store: MusicSourceStore(FakePersistenceService()),
    lyricsProvider: provider,
  );
}

/// A lyrics database that answers with the same text every time.
class _RecordingLyricsProvider implements LyricsProvider {
  final String answer;

  /// The tracks the provider was asked about.
  final List<Song> asked = [];

  _RecordingLyricsProvider(this.answer);

  @override
  Future<String?> lookup(Song song) async {
    asked.add(song);
    return answer;
  }
}
