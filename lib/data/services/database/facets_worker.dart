import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';
import 'package:tune/data/services/database/library_query.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/domain/library_filter.dart';

/// Counts the facets on a second connection, in a worker isolate.
///
/// The groups full-scan the table; on a library of tens of thousands of
/// tracks that is hundreds of milliseconds, and it must not land on the
/// thread that draws. The worker opens its own read connection because a
/// sqlite handle belongs to the isolate that opened it.
Future<LibraryFacets> facetsInBackground({
  required String path,
  required LibraryFilter filter,
}) => Isolate.run(() => _facetsOnPath(path, filter));

LibraryFacets _facetsOnPath(String path, LibraryFilter filter) {
  final db = sqlite3.open(path);
  try {
    return LibraryQuery(db).facets(filter: filter);
  } finally {
    db.close();
  }
}
