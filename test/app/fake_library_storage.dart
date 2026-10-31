import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/taste_aggregates.dart';
import 'package:tune/features/library/data/impl/library_storage_io.dart';
import 'package:tune/features/library/domain/library_filter.dart';

/// A library storage over a database that lives only in memory.
///
/// The tests run against the same upsert, merge and window rules the app
/// runs against, so a fake that drifted from the database cannot pass.
class FakeLibraryStorage extends SqliteLibraryStorage {
  factory FakeLibraryStorage([List<Song> seed = const []]) {
    final storage = FakeLibraryStorage._(AppDatabase.inMemory());
    if (seed.isNotEmpty) storage.database.save(seed);
    return storage;
  }

  FakeLibraryStorage._(this.database) : super(database: () async => database);

  /// The database the windows are read from and written to.
  final AppDatabase database;

  /// How many batches the controller asked to merge in.
  int ingestCount = 0;

  /// Whether the next merge fails, as a full disk does.
  bool failIngest = false;

  /// How many times the controller read a window for a filter.
  int reloadCount = 0;

  @override
  Future<int> ingest(List<Song> songs) async {
    ingestCount += 1;
    if (failIngest) throw StateError('ingest failed');
    return super.ingest(songs);
  }

  @override
  Future<int> countMatching({required String query, String? sourceId}) async {
    reloadCount += 1;
    return super.countMatching(query: query, sourceId: sourceId);
  }

  @override
  Future<int> countQuery({
    required String query,
    required LibraryFilter filter,
  }) async {
    reloadCount += 1;
    return super.countQuery(query: query, filter: filter);
  }

  @override
  Future<TasteAggregates> tasteAggregates() async => TasteAggregates.empty;
}
