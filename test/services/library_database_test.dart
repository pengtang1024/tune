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
        [song(1, added: 1), song(2, added: 2), song(3, added: 3)],
        pinned: {'tune://openverse/1'},
      );

      final removed = database.prune(2);

      expect(removed, {'tune://openverse/2'});
      expect(database.count(), 2);
      expect(
        database.load().map((track) => track.uri),
        containsAll(['tune://openverse/1', 'tune://openverse/3']),
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
