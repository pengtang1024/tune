import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/domain/models/library_sort.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/features/library/data/impl/library_storage_io.dart';

/// The library lives in SQLite: rows are written one by one and a library of
/// a hundred thousand tracks never has to be rewritten as one document.
void main() {
  Song song(int id, {int added = 0}) => Song(
    id: id,
    title: 'Track $id',
    artist: 'Artist',
    uri: 'tune://openverse/$id',
    sourceId: 'openverse',
    externalId: '$id',
    streamUrl: 'https://example.com/$id.mp3',
    dateAdded: added,
  );

  group('library database', () {
    test('prune keeps the pinned and the newest tracks of a source', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);

      database.save(
        [
          song(1, added: 1),
          song(2, added: 2),
          song(3, added: 3),
          song(4, added: 4),
        ],
        pinned: {'tune://openverse/1'},
      );

      // The pinned track never counts against the limit: the three unpinned
      // tracks keep the two newest, and the oldest one goes.
      final removed = database.prune(2);

      expect(removed, {'tune://openverse/2'});
      expect(database.count(), 3);
      expect(
        database.load().map((track) => track.uri),
        containsAll([
          'tune://openverse/1',
          'tune://openverse/3',
          'tune://openverse/4',
        ]),
      );
    });

    test('prune never drops the local files', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      const local = Song(id: 9, title: 'Local', uri: '/music/local.mp3');
      database.save([local, song(1), song(2)]);

      database.prune(1);

      expect(
        database.load().map((track) => track.uri),
        contains('/music/local.mp3'),
      );
    });

    test('a track played more often outranks a quieter one', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([song(1, added: 1), song(2, added: 2), song(3, added: 3)]);
      database.markPlayed('tune://openverse/1');
      database.markPlayed('tune://openverse/1');

      final removed = database.prune(1);

      expect(removed, isNot(contains('tune://openverse/1')));
      expect(database.count(), 1);
    });

    test('the marked tracks are grouped for the taste profile', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([
        Song(
          id: 1,
          title: 'A',
          artist: 'Artist A',
          uri: 'tune://openverse/1',
          sourceId: 'openverse',
          year: 1990,
          genre: 'rock',
        ),
        Song(
          id: 2,
          title: 'B',
          artist: 'Artist B',
          uri: 'tune://openverse/2',
          sourceId: 'openverse',
          year: 2001,
          genre: 'jazz',
        ),
      ]);
      database.saveFavorites({'tune://openverse/1', 'tune://openverse/2'});

      expect(database.favoriteArtistCounts(), {
        'Artist A': 1,
        'Artist B': 1,
      });
      expect(database.favoriteGenreCounts(), {'rock': 1, 'jazz': 1});
      expect(database.favoriteDecadeCounts(), {1990: 1, 2000: 1});
    });

    test('a pinned track outside the saved window is kept', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([
        song(1, added: 1),
        song(2, added: 2),
        song(3, added: 3),
      ]);

      // The pin is written for a row that is not part of the saved window.
      database.syncPinned({'tune://openverse/3'});
      database.prune(1);

      // The unpinned tracks keep the newest one; the pinned track stays even
      // though it is outside that window.
      final uris = database.load().map((track) => track.uri);
      expect(database.count(), 2);
      expect(uris, contains('tune://openverse/3'));
      expect(uris, contains('tune://openverse/2'));
      expect(uris, isNot(contains('tune://openverse/1')));
    });

    test('a prune larger than the parameter limit still works', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      final songs = [for (var i = 0; i < 1500; i++) song(i, added: i)];
      database.save(songs);

      final removed = database.prune(1);

      expect(removed, hasLength(1499));
      expect(database.count(), 1);
    });

    test('a limit of zero keeps everything', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([song(1), song(2), song(3)]);

      expect(database.prune(0), isEmpty);
      expect(database.count(), 3);
    });

    test('saves and reads the tracks back', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);

      database.save([song(1), song(2)]);

      expect(database.count(), 2);
      expect(
        database.load().map((track) => track.uri),
        containsAll(['tune://openverse/1', 'tune://openverse/2']),
      );
    });

    test('a second save adds the new rows and keeps the old ones', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);

      database.save([song(1), song(2)]);
      database.save([song(2), song(3)]);

      // One window of a large library is written without erasing the rows
      // outside it; removing a source is an explicit call.
      expect(database.count(), 3);
      expect(
        database.load().map((track) => track.uri),
        containsAll([
          'tune://openverse/1',
          'tune://openverse/2',
          'tune://openverse/3',
        ]),
      );
    });

    test('a source can be removed on its own', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([song(1), song(2)]);

      database.removeSource('openverse');

      expect(database.count(), 0);
    });

    test('a page reads the library by title', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([song(1), song(2), song(3)]);

      final page = database.page(offset: 0, limit: 2);
      expect(page, hasLength(2));

      final next = database.page(offset: 2, limit: 2);
      expect(next, hasLength(1));
    });

    test('clearing the database leaves no track', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([song(1)]);

      database.clear();

      expect(database.count(), 0);
      expect(database.load(), isEmpty);
    });

    test('an ingest that brings the same facts back writes nothing', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);

      database.ingestBatch([song(1, added: 1), song(2, added: 2)]);
      final firstSeen = database.load().firstWhere(
        (track) => track.uri == song(1).uri,
      );
      database.ingestBatch([song(1), song(2)]);

      // The unchanged tracks keep the stamp of the first ingest, so the
      // library page does not rebuild for a scan that changed nothing.
      expect(database.ingestBatch([song(1), song(2)]), 0);
      final settled = database.load().firstWhere(
        (track) => track.uri == song(1).uri,
      );
      expect(settled.dateAdded, firstSeen.dateAdded);
    });

    test('an ingest rewrites only the row whose facts changed', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.ingestBatch([song(1), song(2)]);

      final renamed = song(1).copyWith(title: 'Renamed');
      expect(database.ingestBatch([renamed, song(2)]), 1);
      expect(
        database.load().firstWhere((track) => track.uri == song(1).uri).title,
        'Renamed',
      );
    });

    test('an ingest merges the copies another source brings', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.ingestBatch([song(1)]);

      // The same track, met under a folder of its own: one row knows both.
      const copy = Song(
        id: 1,
        title: 'Track 1',
        artist: 'Artist',
        uri: 'tune://openverse/1',
        sourceId: 'openverse',
        externalId: '1',
        localPath: '/music/Artist/Track 1.mp3',
        size: 4096,
      );
      expect(database.ingestBatch([copy]), 1);
      final merged = database.load().single;
      expect(merged.hasRemoteSource, isTrue);
      expect(merged.hasLocalFile, isTrue);
      expect(merged.localPath, copy.localPath);
      // The next scan of either side changes nothing: the merged row is the
      // fixed point of both inputs.
      expect(database.ingestBatch([song(1)]), 0);
      expect(database.ingestBatch([copy]), 0);
    });

    test('the rows of a source that is off leave the page, not the disk', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.ingestBatch([song(1), song(2), song(3)]);
      const local = Song(id: 9, title: 'Local', uri: '/music/local.mp3');
      database.ingestBatch([local]);

      // The source turns off: its three rows leave the page.
      expect(
        database.deactivateUncovered(
          enabledSourceIds: {'local'},
          localPaths: ['/music'],
        ),
        3,
      );
      // The local row sits under the folder the scan reads and stays.
      expect(database.count(), 1);
      expect(database.load().map((track) => track.uri), ['/music/local.mp3']);

      // The folder the scan reads goes away: the local rows leave too.
      expect(
        database.deactivateUncovered(
          enabledSourceIds: {'local'},
          localPaths: ['/elsewhere'],
        ),
        1,
      );
      expect(database.count(), 0);

      // Every row is still on the disk, and the next scan of the source
      // brings it back.
      expect(database.ingestBatch([song(1)]), 1);
      expect(database.count(), 1);
    });

    test('a folder scan leaves the rows of the system library alone', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      const content = Song(
        id: 1,
        title: 'Phone track',
        uri: 'content://media/external/audio/media/1',
      );
      const file = Song(id: 2, title: 'Disk track', uri: '/music/disk.mp3');
      database.ingestBatch([content, file]);

      // A `content://` address names the system library, not a folder, so
      // the folders a scan reads cannot say the row is gone.
      expect(
        database.deactivateUncovered(
          enabledSourceIds: {'local'},
          localPaths: ['/music'],
        ),
        0,
      );
      expect(database.count(), 2);
    });

    test('a read of the system library answers for the local source', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      const kept = Song(
        id: 1,
        title: 'Kept',
        uri: 'content://media/external/audio/media/1',
      );
      const gone = Song(
        id: 2,
        title: 'Gone',
        uri: 'content://media/external/audio/media/2',
      );
      const legacy = Song(
        id: 3,
        title: 'Legacy',
        uri: '/storage/emulated/0/Music/old.mp3',
      );
      database.ingestBatch([kept, gone, legacy]);

      // The read is the whole library: a row it did not bring has left the
      // phone, whatever address it carries.
      expect(
        database.deactivateUncovered(
          enabledSourceIds: {'local'},
          localPaths: const [],
          localReadUris: {kept.uri},
        ),
        2,
      );
      expect(database.load().map((track) => track.uri), [kept.uri]);
    });

    test('albums merge the episodes of a show and leave a station out', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([
        const Song(
          id: 1,
          title: 'Episode 1',
          artist: 'Host A',
          album: 'The Show',
          uri: 'tune://podcast/1',
          sourceId: 'podcast_rss-1',
        ),
        const Song(
          id: 2,
          title: 'Episode 2',
          artist: 'Host B',
          album: 'The Show',
          uri: 'tune://podcast/2',
          sourceId: 'podcast_rss-1',
        ),
        const Song(
          id: 3,
          title: 'Episode 1',
          artist: 'Host C',
          album: 'The Show',
          uri: 'tune://podcast/3',
          sourceId: 'podcast_rss-2',
        ),
        const Song(
          id: 4,
          title: 'Station',
          artist: 'On air artist',
          album: 'On air song',
          uri: 'tune://radio/1',
          sourceId: 'radio',
          isLiveStream: true,
        ),
      ]);

      final albums = database.albumSummaries();

      expect(albums, hasLength(2));
      expect(albums.any((album) => album.key.contains('radio')), isFalse);
      final show = albums.firstWhere(
        (album) => album.key.contains('podcast_rss-1'),
      );
      expect(show.trackCount, 2);
      expect(show.kind, ContentKind.podcast);
      expect(database.albumSongs(show.key).map((song) => song.title), [
        'Episode 1',
        'Episode 2',
      ]);
    });

    test('an album carries the kind of its tracks', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([
        const Song(
          id: 1,
          title: 'Song',
          artist: 'Artist',
          album: 'Record',
          uri: '/music/1.mp3',
        ),
        const Song(
          id: 2,
          title: 'Chapter',
          album: 'Book',
          uri: 'tune://librivox/1',
          sourceId: 'librivox',
        ),
      ]);

      final albums = database.albumSummaries();

      expect(
        albums.firstWhere((album) => album.name == 'Record').kind,
        ContentKind.music,
      );
      expect(
        albums.firstWhere((album) => album.name == 'Book').kind,
        ContentKind.audiobook,
      );
    });

    test('the filter counts the four kinds of track', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([
        song(1),
        const Song(
          id: 2,
          title: 'Episode',
          album: 'Show',
          uri: 'tune://podcast/1',
          sourceId: 'podcast_rss-1',
        ),
        const Song(
          id: 3,
          title: 'Chapter',
          album: 'Book',
          uri: 'tune://librivox/1',
          sourceId: 'librivox',
        ),
        const Song(
          id: 4,
          title: 'Station',
          uri: 'tune://radio/1',
          sourceId: 'radio-1',
          isLiveStream: true,
        ),
      ]);

      final facets = database.facets(filter: LibraryFilter.empty);

      expect(facets.kinds, {
        ContentKind.music: 1,
        ContentKind.podcast: 1,
        ContentKind.audiobook: 1,
        ContentKind.radio: 1,
      });
    });

    test('a kind filter keeps only the chosen kind', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([
        song(1),
        const Song(
          id: 2,
          title: 'Episode',
          album: 'Show',
          uri: 'tune://podcast/1',
          sourceId: 'podcast_rss-1',
        ),
        const Song(
          id: 3,
          title: 'Station',
          uri: 'tune://radio/1',
          sourceId: 'radio-1',
          isLiveStream: true,
        ),
      ]);

      List<Song> read(ContentKind kind) => database.query(
        query: '',
        filter: LibraryFilter(kinds: {kind}),
        sort: LibrarySort.recent,
        offset: 0,
        limit: 10,
      );

      expect(read(ContentKind.podcast).map((track) => track.title), [
        'Episode',
      ]);
      expect(read(ContentKind.radio).map((track) => track.title), [
        'Station',
      ]);
      expect(read(ContentKind.music).map((track) => track.title), ['Track 1']);
    });

    test('a music album still asks for its artist', () {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      database.save([
        const Song(
          id: 1,
          title: 'Left',
          artist: 'Left Artist',
          album: 'Greatest Hits',
          uri: 'tune://openverse/l',
        ),
        const Song(
          id: 2,
          title: 'Right',
          artist: 'Right Artist',
          album: 'Greatest Hits',
          uri: 'tune://openverse/r',
        ),
      ]);

      final albums = database.albumSummaries();

      expect(albums, hasLength(2));
      expect(albums.map((album) => album.trackCount), [1, 1]);
    });
  });

  group('sqlite storage', () {
    test('moves the old json document into the database', () async {
      final root = await Directory.systemTemp.createTemp('tune-db-test');
      addTearDown(() => root.delete(recursive: true));

      final library = Directory('${root.path}/library')
        ..createSync(recursive: true);
      final document = File('${library.path}/scanned_songs.json')
        ..writeAsStringSync(jsonEncode([song(1).toJson(), song(2).toJson()]));

      final storage = SqliteLibraryStorage(supportDirectory: () async => root);

      final songs = await storage.load();

      expect(songs, hasLength(2));
      expect(File('${document.path}.migrated').existsSync(), isTrue);
      expect(document.existsSync(), isFalse);
    });

    test('saving and clearing go through the database', () async {
      final root = await Directory.systemTemp.createTemp('tune-db-test');
      addTearDown(() => root.delete(recursive: true));

      final storage = SqliteLibraryStorage(supportDirectory: () async => root);

      await storage.save([song(1)]);
      expect(await storage.load(), hasLength(1));

      await storage.clear();
      expect(await storage.load(), isEmpty);
    });
  });
}
