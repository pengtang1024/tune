import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/data/library_storage.dart';

/// The library storage of a build without a file system.
///
/// The web build is no longer a target of the app, so it keeps no library:
/// the songs the sources bring in live in memory for the session and are gone
/// on reload. A desktop build keeps them in SQLite.
LibraryStorage createLibraryStorage(PersistenceService persistence) =>
    const EmptyLibraryStorage();

class EmptyLibraryStorage implements LibraryStorage {
  const EmptyLibraryStorage();

  @override
  Future<List<Song>> load() async => const [];

  @override
  Future<void> save(List<Song> songs) async {}

  @override
  Future<void> clear() async {}
}
