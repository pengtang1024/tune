import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
