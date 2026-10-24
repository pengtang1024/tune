import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/data/impl/library_storage_stub.dart';

import '../services/fake_persistence.dart';

/// The library of the web build lives in the browser store.
///
/// The store keeps the library between two visits, so a return to the page
/// shows the same songs instead of an empty library.
void main() {
  late FakePersistenceService persistence;

  setUp(() {
    persistence = FakePersistenceService();
  });

  BrowserLibraryStorage storage() => BrowserLibraryStorage(persistence);

  test('a saved library is read back', () async {
    final service = storage();
    await service.save([
      const Song(
        id: 1,
        title: 'Night Flight',
        artist: 'Forest Radio',
        uri: 'https://example.com/a.mp3',
      ),
    ]);

    final songs = await service.load();

    expect(songs, hasLength(1));
    expect(songs.single.title, 'Night Flight');
    expect(songs.single.artist, 'Forest Radio');
  });

  test('the library is kept in the browser store', () async {
    await storage().save([const Song(id: 1, uri: 'https://example.com/a.mp3')]);

    expect(persistence.values, contains(BrowserLibraryStorage.key));
  });

  test('a library that was never written holds no songs', () async {
    expect(await storage().load(), isEmpty);
  });

  test('a cleared library holds no songs', () async {
    final service = storage();
    await service.save([const Song(id: 1, uri: 'https://example.com/a.mp3')]);

    await service.clear();

    expect(await service.load(), isEmpty);
  });

  test('a broken document holds no songs', () async {
    await persistence.setString(BrowserLibraryStorage.key, 'not json');

    expect(await storage().load(), isEmpty);
  });
}
