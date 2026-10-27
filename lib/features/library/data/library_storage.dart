import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/taste_aggregates.dart';
import 'package:tune/features/library/domain/album_summary.dart';

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

  /// Reads one window of the tracks that match [query] and [sourceId].
  Future<List<Song>> search({
    required String query,
    String? sourceId,
    required int offset,
    required int limit,
  });

  /// How many tracks match [query] and [sourceId].
  Future<int> countMatching({required String query, String? sourceId});

  /// The albums of the library, without their tracks.
  Future<List<AlbumSummary>> albumSummaries();

  /// The tracks of one album.
  Future<List<Song>> albumSongs(String key);

  /// Removes the tracks of one source.
  Future<void> removeSource(String sourceId);

  /// The counts a taste profile needs, without loading every track.
  Future<TasteAggregates> tasteAggregates();

  /// Marks exactly [ids] as pinned, so a prune keeps them.
  Future<void> syncPinned(Set<String> ids);

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
