import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

import 'fake_persistence.dart';

/// End-to-end check of the whole chain the app uses:
/// built-in config -> MusicSourceService -> adapter registry -> real API -> Song.
///
/// The other live test calls the adapters directly, so it would still pass if
/// a new source was never registered in the service.
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  final online = await _isOnline();
  const offline = 'This machine has no internet connection.';

  test(
    'the service scans the new built-in sources through the real network',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // The configs the app ships with, not hand-made ones.
      final sources = BuiltInMusicSources.defaults
          .where((config) => const {'ccmixter', 'audius'}.contains(config.id))
          .map(
            (config) => config.copyWith(
              settings: {...config.settings, 'query': 'jazz'},
            ),
          )
          .toList();

      expect(sources, hasLength(2));

      final results = await service.search(sources: sources, query: 'jazz');

      expect(results, hasLength(2));
      for (final result in results) {
        expect(
          result.status,
          SourceScanStatus.success,
          reason: '${result.sourceId} failed: ${result.message}',
        );
        expect(
          result.songs,
          isNotEmpty,
          reason: '${result.sourceId} returned nothing',
        );

        final song = result.songs.first;
        expect(song.sourceId, result.sourceId);
        expect(song.title, isNotEmpty);
        expect(song.artist, isNotEmpty);
        expect(song.streamUrl, startsWith('https://'));
        expect(song.uri, startsWith('tune://${result.sourceId}/'));
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the built-in PeerTube source plays audio files of the federation',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // The instance the app ships with, in its music category.
      final peers = await service.scanAll(
        sources: [BuiltInMusicSources.peerTube],
        localPaths: const [],
      );

      final result = peers.single;
      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'peertube failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty);

      final song = result.songs.first;
      expect(song.title, isNotEmpty);
      expect(song.streamUrl, startsWith('https://'));
      expect(song.externalId, isNotNull);
      expect(song.duration, greaterThan(0));
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );

  test(
    'the built-in archive collections expand their items into tracks',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // The queries the app ships with. A collection name alone returns the
      // directory page of the collection, which reads as an item with no
      // audio files, so this catches a keyword that lost its type filter.
      final sources = BuiltInMusicSources.defaults
          .where((config) => config.sourceType == 'internet_archive')
          .toList(growable: false);
      expect(
        sources.map((config) => config.id),
        containsAll([
          'live_music_archive',
          'great78',
          'netlabels',
          'old_time_radio',
          'archive_music',
          'unlocked_recordings',
          'community_music',
          'independent_audiobooks',
          'archive_podcasts',
        ]),
      );

      final results = await service.scanAll(
        sources: sources,
        localPaths: const [],
      );

      for (final result in results) {
        expect(
          result.status,
          SourceScanStatus.success,
          reason: '${result.sourceId} failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: result.sourceId);
        expect(
          result.songs.first.streamUrl ?? '',
          startsWith('https://'),
          reason: result.sourceId,
        );
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 240)),
  );

  test(
    'the service reads the stations of an AzuraCast server',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // The public demo server of AzuraCast; its stations need no key.
      final azuracast = BuiltInMusicSources.azuracast.copyWith(
        enabled: true,
        settings: {
          'server': 'https://demo.azuracast.com',
          'apiKey': '',
          'query': '',
        },
      );

      final result = (await service.scanAll(
        sources: [azuracast],
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'AzuraCast failed: ${result.message}',
      );
      expect(
        result.songs,
        isNotEmpty,
        reason: 'AzuraCast returned nothing: ${result.message}',
      );

      final song = result.songs.first;
      expect(song.isLiveStream, isTrue);
      expect(song.title, isNotEmpty);
      expect(song.streamUrl, startsWith('http'));
      expect(song.sourceId, azuracast.id);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the service scans LibriVox into whole chapters',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // The built-in configuration of LibriVox: no keyword, no limits set.
      // A scan without a keyword reads the books everybody listens to.
      final result = (await service.scanAll(
        sources: BuiltInMusicSources.defaults
            .where((config) => config.id == 'librivox')
            .toList(),
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'LibriVox failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty, reason: 'LibriVox returned nothing');

      // One book is fetched for each of its chapters, so every chapter of
      // the scan carries the album of the book it belongs to.
      final albums = result.songs.map((song) => song.album).toSet();
      expect(albums.where((album) => album.isEmpty), isEmpty);
      expect(result.songs.first.trackNumber, isNotNull);
      expect(result.songs.first.streamUrl, startsWith('https://'));
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );

  test(
    'the radio source reads the stations of any country',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );
      final radio = BuiltInMusicSources.radio;

      for (final country in const ['SG', 'MY', 'AU']) {
        final result = (await service.scanAll(
          sources: [
            radio.copyWith(
              settings: {
                'provider': 'browser',
                'country': country,
                'query': '',
              },
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$country failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$country returned nothing');
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the playlist mode of Deezer reads the songs of a playlist',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final result = (await service.scanAll(
        sources: [
          BuiltInMusicSources.deezer.copyWith(
            settings: {
              'query': 'smooth jazz',
              'genre': '',
              'mode': 'playlists',
              'limit': '4',
            },
          ),
        ],
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'Deezer playlists failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty);
      // A playlist may hold hundreds of songs; the scan keeps the window of
      // the limit, three playlists at most.
      expect(result.songs.length, lessThanOrEqualTo(12));
      expect(
        result.songs.every((song) => song.artist.isNotEmpty && song.album.isNotEmpty),
        isTrue,
      );
      expect(result.songs.every((song) => song.duration == 30000), isTrue);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the artist mode of Deezer reads the top songs of an artist',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final result = (await service.scanAll(
        sources: [
          BuiltInMusicSources.deezer.copyWith(
            settings: {
              'query': 'miles davis',
              'genre': '',
              'mode': 'artists',
              'limit': '5',
            },
          ),
        ],
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'Deezer artists failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty);
      // The artist mode reads the top songs of the artist the keyword names.
      expect(
        result.songs.every((song) => song.artist.contains('Miles Davis')),
        isTrue,
        reason: 'artists were ${result.songs.map((s) => s.artist).toSet()}',
      );
      expect(result.songs.every((song) => song.duration == 30000), isTrue);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the album mode of Deezer hands over whole records',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final result = (await service.scanAll(
        sources: [
          BuiltInMusicSources.deezer.copyWith(
            settings: {
              'query': 'kind of blue',
              'genre': '',
              'mode': 'albums',
              'limit': '6',
            },
          ),
        ],
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'Deezer albums failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty);

      // The songs of a record arrive together, with the name of their album.
      final albums = result.songs.map((song) => song.album).toSet();
      expect(albums, isNotEmpty);
      expect(
        result.songs.where((song) => song.album == albums.first).length,
        greaterThan(1),
      );
      expect(result.songs.every((song) => song.duration == 30000), isTrue);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the Deezer charts answer with playable previews',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      for (final reach in const ['', 'jazz', 'classical']) {
        final result = (await service.scanAll(
          sources: [
            BuiltInMusicSources.deezer.copyWith(
              settings: {'query': '', 'genre': reach, 'limit': '3'},
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: 'Deezer $reach failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: 'Deezer $reach was empty');
        expect(result.songs.first.streamUrl, contains('.mp3'));
        expect(result.songs.first.duration, 30000);
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the reaches of Audius answer with tracks of that reach',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      for (final genre in const ['Jazz', 'Classical', 'Ambient']) {
        final result = (await service.scanAll(
          sources: [
            BuiltInMusicSources.audius.copyWith(
              settings: {'genre': genre, 'window': 'week', 'limit': '3'},
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$genre failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$genre returned nothing');
        // The network filters by the reach itself, so every track of the
        // answer must carry the reach that was asked for.
        expect(
          result.songs.every((song) => song.genre == genre),
          isTrue,
          reason: '$genre answered ${result.songs.map((s) => s.genre).toSet()}',
        );
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the kinds of book of LibriVox answer with different books',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );
      final books = BuiltInMusicSources.librivox;

      final firstBooks = <String>{};
      for (final genre in const ['Poetry', 'History', 'Science Fiction']) {
        final result = (await service.scanAll(
          sources: [
            books.copyWith(
              settings: {'genre': genre, 'limit': '1', 'language': ''},
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$genre failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$genre returned nothing');
        final album = result.songs.first.album;
        expect(album, isNotEmpty);
        // The kinds are shelves of the catalogue, so a scan of one kind must
        // not answer with the book of another.
        expect(firstBooks.add(album), isTrue, reason: '$genre repeated $album');
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );

  test(
    'the radio source reads a language of the directory',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );
      final radio = BuiltInMusicSources.radio;

      final names = <String>{};
      for (final language in const ['spanish', 'japanese', 'french']) {
        final result = (await service.scanAll(
          sources: [
            radio.copyWith(
              settings: {
                'provider': 'browser',
                'language': language,
                'tag': '',
                'query': '',
                'limit': '3',
              },
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$language failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$language returned nothing');
        // The tongues are separate reaches of the directory, so a scan of one
        // tongue must not answer with the stations of another.
        for (final song in result.songs) {
          expect(
            names.add(song.title),
            isTrue,
            reason: '$language repeated ${song.title}',
          );
        }
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the radio source reads a tag of the directory',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );
      final radio = BuiltInMusicSources.radio;

      for (final tag in const ['jazz', 'classical', 'news']) {
        final result = (await service.scanAll(
          sources: [
            radio.copyWith(
              settings: {
                'provider': 'browser',
                'tag': tag,
                'query': '',
                'limit': '5',
              },
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$tag failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$tag returned nothing');
        expect(result.songs.first.streamUrl, startsWith('http'));
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the service reads the previews of the iTunes store',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // The store answers only a keyword, so the instance is given one.
      final source = BuiltInMusicSources.itunes.copyWith(
        enabled: true,
        settings: const {
          'query': 'miles davis',
          'country': 'US',
          'limit': '2',
        },
      );

      final result = (await service.scanAll(
        sources: [source],
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'iTunes failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty);

      final song = result.songs.first;
      expect(song.artist, isNotEmpty);
      expect(song.streamUrl, startsWith('https://'));
      // The playable file is a preview, so the track lasts thirty seconds.
      expect(song.duration, 30000);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the artist mode of the store reads an artist catalogue',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final result = (await service.scanAll(
        sources: [
          BuiltInMusicSources.itunes.copyWith(
            enabled: true,
            settings: const {
              'query': 'miles davis',
              'country': 'US',
              'limit': '4',
              'mode': 'artists',
            },
          ),
        ],
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'iTunes artists failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty);
      // The mode reads the catalogue of the artists the keyword names, so the
      // songs carry a record and a performer.
      expect(
        result.songs.every((song) => song.album.isNotEmpty && song.artist.isNotEmpty),
        isTrue,
      );
      expect(result.songs.every((song) => song.duration == 30000), isTrue);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'each new category of the commons answers with its own audio',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final seen = <String, Set<String>>{};
      for (final category in const [
        'rock',
        'hiphop',
        'country',
        'blues',
        'reggae',
        'choral',
        'organ',
      ]) {
        final result = (await service.scanAll(
          sources: [
            BuiltInMusicSources.wikimedia.copyWith(
              settings: {'query': '', 'category': category, 'limit': '6'},
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$category failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$category returned nothing');
        seen[category] = result.songs.map((song) => song.title).toSet();
      }

      // The categories are separate reaches of the commons.
      expect(seen['rock'], isNot(equals(seen['organ'])));
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 240)),
  );

  test(
    'the Openverse source reads one catalogue at a time',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final seen = <String, Set<String>>{};
      for (final source in const ['jamendo', 'freesound']) {
        final result = (await service.scanAll(
          sources: [
            BuiltInMusicSources.openverse.copyWith(
              settings: {'query': '', 'source': source},
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$source failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$source returned nothing');
        seen[source] = result.songs.map((song) => song.title).toSet();
      }

      // The catalogues are separate: a music catalogue and a sound effect
      // catalogue must not answer with the same tracks.
      expect(seen['jamendo'], isNot(equals(seen['freesound'])));
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the podcast directory reads a tag of its own',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final showsOfTag = <String, Set<String>>{};
      for (final tag in const ['comedy', 'technology']) {
        final result = (await service.scanAll(
          sources: [
            BuiltInMusicSources.podcastCatalog.copyWith(
              settings: {'tag': tag, 'limit': '2'},
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$tag failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$tag returned nothing');
        final shows = result.songs
            .map((song) => song.album)
            .where((album) => album.isNotEmpty)
            .toSet();
        expect(shows, isNotEmpty, reason: tag);
        showsOfTag[tag] = shows;
      }
      // The tags are separate reaches of the directory, so the two scans must
      // not answer with the same shows.
      expect(showsOfTag['comedy'], isNot(equals(showsOfTag['technology'])));
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );

  test(
    'every read mode of Deezer works without a keyword',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      for (final mode in const ['songs', 'albums', 'artists', 'playlists']) {
        final result = (await service.scanAll(
          sources: [
            BuiltInMusicSources.deezer.copyWith(
              settings: {'query': '', 'genre': '', 'mode': mode, 'limit': '4'},
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '$mode failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '$mode returned nothing');
        expect(
          result.songs.every((song) => song.artist.isNotEmpty),
          isTrue,
          reason: mode,
        );
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );

  test(
    'the album modes of the stores read the album chart without a keyword',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final albums = BuiltInMusicSources.defaults
          .where((config) => const {'itunes', 'deezer'}.contains(config.id))
          .map(
            (config) => config.copyWith(
              enabled: true,
              settings: {'query': '', 'mode': 'albums', 'limit': '6'},
            ),
          )
          .toList();

      final results = await service.scanAll(
        sources: albums,
        localPaths: const [],
      );

      for (final result in results) {
        expect(
          result.status,
          SourceScanStatus.success,
          reason: '${result.sourceId} failed: ${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: result.sourceId);
        // The chart is read as albums, so the songs come with their record.
        expect(
          result.songs.every((song) => song.album.isNotEmpty),
          isTrue,
          reason: result.sourceId,
        );
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );

  test(
    'the album mode of the store hands over whole records',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final source = BuiltInMusicSources.itunes.copyWith(
        enabled: true,
        settings: const {
          'query': 'kind of blue miles davis',
          'country': 'US',
          'limit': '10',
          'mode': 'albums',
        },
      );

      final result = (await service.scanAll(
        sources: [source],
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'iTunes albums failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty);

      // The songs of an album stay together: more than one track of the same
      // record arrives in one scan.
      final albums = result.songs.map((song) => song.album).toSet();
      expect(albums, isNotEmpty);
      expect(
        result.songs.where((song) => song.album == albums.first).length,
        greaterThan(1),
      );
      expect(result.songs.every((song) => song.duration == 30000), isTrue);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the service reads the Apple podcast directory',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // Two shows are enough to prove the chart, the lookup and the feed of
      // every show answer; the default of five makes the test slower.
      final source = BuiltInMusicSources.podcastApple.copyWith(
        settings: {
          ...BuiltInMusicSources.podcastApple.settings,
          'limit': '2',
        },
      );

      final result = (await service.scanAll(
        sources: [source],
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'Apple directory failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty);

      final song = result.songs.first;
      expect(song.album, isNotEmpty);
      expect(song.streamUrl, startsWith('https://'));
      expect(song.title, isNotEmpty);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the service reads the podcast directory',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final result = (await service.search(
        sources: BuiltInMusicSources.defaults
            .where((config) => config.id == 'podcast_catalog')
            .toList(),
        query: 'jazz',
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'Podcast directory failed: ${result.message}',
      );
      expect(
        result.songs,
        isNotEmpty,
        reason: 'Podcast directory returned nothing: ${result.message}',
      );

      final song = result.songs.first;
      expect(song.album, isNotEmpty);
      expect(song.streamUrl, startsWith('http'));
      expect(song.title, isNotEmpty);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );
}

class _NoopScanner extends CrossPlatformMusicScannerImpl {
  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async => const [];
}

Future<bool> _isOnline() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
  try {
    final response = await dio.get<String>(
      'https://itunes.apple.com/search',
      queryParameters: {'term': 'tune', 'media': 'music', 'limit': 1},
      options: Options(responseType: ResponseType.plain),
    );
    return response.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    dio.close(force: true);
  }
}
