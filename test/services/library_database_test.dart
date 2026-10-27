import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/data/impl/library_database.dart';
import 'package:tune/features/library/data/impl/library_storage_io.dart';

/// The library lives in SQLite: rows are written one by one and a library of
/// a hundred thousand tracks never has to be rewritten as one document.
void main() {
  Song song(int id) => Song(
    id: id,
    title: 'Track $id',
    artist: 'Artist',
    uri: 'tune://openverse/$id',
    sourceId: 'openverse',
    externalId: '$id',
    streamUrl: 'https://example.com/$id.mp3',
  );

  group('library database', () {
    test('saves and reads the tracks back', () {
      final database = LibraryDatabase.inMemory();
      addTearDown(database.close);

      database.save([song(1), song(2)]);

      expect(database.count(), 2);
      expect(
        database.load().map((track) => track.uri),
        containsAll(['tune://openverse/1', 'tune://openverse/2']),
      );
    });

    test('a second save keeps the old rows and removes the gone ones', () {
      final database = LibraryDatabase.inMemory();
      addTearDown(database.close);

      database.save([song(1), song(2)]);
      database.save([song(2), song(3)]);

      expect(database.count(), 2);
      expect(
        database.load().map((track) => track.uri),
        containsAll(['tune://openverse/2', 'tune://openverse/3']),
      );
      expect(
        database.load().map((track) => track.uri),
        isNot(contains('tune://openverse/1')),
      );
    });

    test('clearing the database leaves no track', () {
      final database = LibraryDatabase.inMemory();
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
