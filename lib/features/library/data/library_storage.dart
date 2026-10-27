import 'package:tune/domain/models/song.dart';

/// The library of the app, as the songs it holds.
///
/// The storage owns the library, and how it is kept follows the platform: a
/// build with a file system keeps the tracks in SQLite, the web build keeps
/// none.
abstract class LibraryStorage {
  /// The songs of the library, empty when the library holds none.
  Future<List<Song>> load();

  /// Writes the songs into the library.
  Future<void> save(List<Song> songs);

  /// Removes the library.
  Future<void> clear();
}
