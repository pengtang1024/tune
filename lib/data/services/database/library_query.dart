import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:tune/data/services/database/library_facets_query.dart';
import 'package:tune/data/services/database/library_filter_sql.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/library_facets.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/domain/models/library_sort.dart';

/// The queries the library page and the filter panel read.
///
/// The filters run in SQL, not over a list in memory: the library stays a
/// window of a table, and a reader with twenty thousand tracks pays for
/// the rows they see. The rules live in [LibraryFilterSql]; the memory
/// storage and the tests keep the same semantics.
class LibraryQuery {
  LibraryQuery(this._db);

  final Database _db;

  /// One window of the tracks that match [query] and [filter], in [sort].
  List<Song> songs({
    required String query,
    required LibraryFilter filter,
    required LibrarySort sort,
    required int offset,
    required int limit,
  }) {
    final where = LibraryFilterSql.where(query, filter);
    final rows = _db.select(
      'SELECT songs.json AS json FROM songs ${where.sql} '
      'ORDER BY ${_order(sort)} LIMIT ? OFFSET ?',
      [...where.args, limit, offset],
    );
    return _songsOf(rows);
  }

  /// How many tracks match [query] and [filter].
  int count({required String query, required LibraryFilter filter}) {
    final where = LibraryFilterSql.where(query, filter);
    final rows = _db.select(
      'SELECT COUNT(*) AS count FROM songs ${where.sql}',
      where.args,
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  /// The counts of every facet group, each counted without its own group's
  /// selection so the other options stay visible while one is chosen.
  LibraryFacets facets({required LibraryFilter filter}) =>
      LibraryFacetsQuery(_db).facets(filter: filter);

  // ---------------------------------------------------------------------
  // ORDER

  static String _order(LibrarySort sort) {
    final direction = sort.ascending ? 'ASC' : 'DESC';
    return switch (sort.field) {
      // The tie break follows the direction, so one index serves both
      // directions: walking it backwards is the descending order.
      LibrarySortField.title =>
        'songs.title_sort COLLATE NOCASE $direction, songs.uri $direction',
      // Newest first is the default order, and it is also the order the
      // partial index on (date_added, uri) stores. A row without an added
      // time sorts last on its own, because zero is smaller than any time.
      LibrarySortField.addedAt => sort.ascending
          ? 'CASE WHEN songs.date_added <= 0 THEN 1 ELSE 0 END ASC, '
                'songs.date_added ASC, songs.uri'
          : 'songs.date_added DESC, songs.uri',
      LibrarySortField.artist =>
        "CASE WHEN songs.artist = '' THEN 1 ELSE 0 END ASC, "
            'songs.artist COLLATE NOCASE $direction, songs.uri',
      LibrarySortField.album =>
        "CASE WHEN songs.album = '' THEN 1 ELSE 0 END ASC, "
            'songs.album COLLATE NOCASE $direction, songs.uri',
      LibrarySortField.duration =>
        'CASE WHEN songs.duration <= 0 THEN 1 ELSE 0 END ASC, '
            'songs.duration $direction, songs.uri',
    };
  }

  // ---------------------------------------------------------------------

  static List<Song> _songsOf(ResultSet rows) {
    final songs = <Song>[];
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row['json'] as String);
        if (decoded is! Map<String, dynamic>) continue;
        songs.add(Song.fromMap(decoded));
      } catch (_) {
        // One broken row must not take the whole window down.
      }
    }
    return songs;
  }
}
