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
  ///
  /// A pinned track (a favorite, a queued track) is marked so a later prune
  /// never drops it.
  Future<void> save(List<Song> songs, {Set<String> pinned = const {}});

  /// Drops the least valuable tracks of every remote source beyond [limit].
  ///
  /// Returns the addresses that were removed. A build without a database
  /// keeps everything and answers with nothing.
  Future<List<String>> prune(int limit);

  /// Notes that a track played, which raises its place in the ranking.
  Future<void> markPlayed(String uri);

  /// Removes the library.
  Future<void> clear();
}
