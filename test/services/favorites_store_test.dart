import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/favorites/data/favorites_store.dart';

import 'fake_persistence.dart';

/// The marks live in SQLite; the old JSON list is moved in once.
void main() {
  test('the old json marks move into the database', () async {
    final root = await Directory.systemTemp.createTemp('tune-favorites');
    addTearDown(() => root.delete(recursive: true));

    final persistence = FakePersistenceService();
    await persistence.setStringList('favorite_tracks', [
      'tune://a',
      'tune://b',
    ]);

    final store = FavoritesStore(
      persistence,
      supportDirectory: () async => root,
    );
    await store.init();

    expect(store.read(), {'tune://a', 'tune://b'});
    expect(Directory('${root.path}/library').existsSync(), isTrue);
  });

  test('a mark written after the database opens is read back', () async {
    final root = await Directory.systemTemp.createTemp('tune-favorites');
    addTearDown(() => root.delete(recursive: true));

    final store = FavoritesStore(
      FakePersistenceService(),
      supportDirectory: () async => root,
    );
    await store.init();
    await store.write({'tune://c'});

    final reopened = FavoritesStore(
      FakePersistenceService(),
      supportDirectory: () async => root,
    );
    await reopened.init();

    expect(reopened.read(), {'tune://c'});
  });
}
