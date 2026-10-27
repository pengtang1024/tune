import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/taste_aggregates.dart';

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
  /// The rows are upserted and nothing else is touched: a caller that holds
  /// one window of a large library must not erase the rows outside it. A
  /// pinned track (a favorite) is marked so a later prune never drops it.
  Future<void> save(List<Song> songs, {Set<String> pinned = const {}});

  /// How many tracks the library holds.
  Future<int> count();

  /// Reads one window of the library, ordered by title.
  Future<List<Song>> page({required int offset, required int limit});

  /// Removes the tracks of one source.
  Future<void> removeSource(String sourceId);

  /// The counts a taste profile needs, without loading every track.
  Future<TasteAggregates> tasteAggregates();

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
