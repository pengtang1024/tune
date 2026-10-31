import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/taste_aggregates.dart';
import 'package:tune/features/library/domain/album_summary.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_sort.dart';
import 'package:tune/features/library/domain/library_view.dart';
import 'package:tune/features/library/data/library_storage.dart';

/// The library storage of a build without a file system.
///
/// The web build is no longer a target of the app, so it keeps no library:
/// the songs the sources bring in live in memory for the session and are gone
/// on reload. A desktop build keeps them in SQLite.
LibraryStorage createLibraryStorage(
  PersistenceService persistence, {
  Future<AppDatabase> Function()? database,
}) => const EmptyLibraryStorage();

class EmptyLibraryStorage implements LibraryStorage {
  const EmptyLibraryStorage();

  @override
  Future<List<Song>> load() async => const [];

  @override
  Future<void> save(List<Song> songs, {Set<String> pinned = const {}}) async {}

  @override
  Future<int> ingest(List<Song> songs) async => 0;

  @override
  Future<int> deactivateUncovered({
    required Set<String> enabledSourceIds,
    required List<String> localPaths,
  }) async => 0;

  @override
  Future<int> count() async => 0;

  @override
  Future<List<Song>> page({required int offset, required int limit}) async =>
      const [];

  @override
  Future<List<Song>> search({
    required String query,
    String? sourceId,
    required int offset,
    required int limit,
  }) async => const [];

  @override
  Future<int> countMatching({required String query, String? sourceId}) async =>
      0;

  @override
  Future<List<Song>> query({
    required String query,
    required LibraryFilter filter,
    required LibrarySort sort,
    required int offset,
    required int limit,
  }) async => const [];

  @override
  Future<int> countQuery({
    required String query,
    required LibraryFilter filter,
  }) async => 0;

  @override
  Future<LibraryFacets> facets({required LibraryFilter filter}) async =>
      LibraryFacets.empty;

  @override
  Future<LibraryView?> loadView() async => null;

  @override
  Future<void> saveView(LibraryView view) async {}

  @override
  Future<List<AlbumSummary>> albumSummaries() async => const [];

  @override
  Future<List<Song>> albumSongs(String key) async => const [];

  @override
  Future<void> removeSource(String sourceId) async {}

  @override
  Future<TasteAggregates> tasteAggregates() async => TasteAggregates.empty;

  @override
  Future<void> syncPinned(Set<String> ids) async {}

  @override
  Future<List<String>> prune(int limit) async => const [];

  @override
  Future<void> markPlayed(String uri) async {}

  @override
  Future<void> clear() async {}
}
