import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_sort.dart';

/// The queries the library page and the filter panel read.
///
/// The filters run in SQL, not over a list in memory: the library stays a
/// window of a table, and a reader with twenty thousand tracks pays for
/// the rows they see. The rules live here once; the memory storage and the
/// tests keep the same semantics.
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
    final where = _where(query, filter);
    final rows = _db.select(
      'SELECT songs.json AS json FROM songs ${where.sql} '
      'ORDER BY ${_order(sort)} LIMIT ? OFFSET ?',
      [...where.args, limit, offset],
    );
    return _songsOf(rows);
  }

  /// How many tracks match [query] and [filter].
  int count({required String query, required LibraryFilter filter}) {
    final where = _where(query, filter);
    final rows = _db.select(
      'SELECT COUNT(*) AS count FROM songs ${where.sql}',
      where.args,
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  /// The counts of every facet group, each counted without its own group's
  /// selection so the other options stay visible while one is chosen.
  LibraryFacets facets({required LibraryFilter filter}) {
    final genres = _genreFacets(filter.copyWith(genres: const {}));
    final decades = _intFacets(
      filter.copyWith(decades: const {}),
      "(songs.year / 10) * 10",
      extra: 'songs.year > 0',
    );
    final artists = _stringFacets(
      filter.copyWith(artists: const {}),
      'songs.artist',
    );
    final sources = _stringFacets(
      filter.copyWith(sources: const {}),
      "COALESCE(songs.source_id, 'local')",
    );
    final languages = _stringFacets(
      filter.copyWith(languages: const {}),
      'songs.language',
    );
    final formats = _stringFacets(
      filter.copyWith(formats: const {}),
      'songs.format',
    );
    final durations = _durationFacets(filter.copyWith(durations: const {}));
    final added = _addedFacets(filter.copyWith(added: const {}));
    final statuses = _statusFacets(filter.copyWith(status: LibraryStatusFilter.all));
    return LibraryFacets(
      genres: genres,
      decades: decades,
      artists: artists,
      sources: sources,
      languages: languages,
      formats: formats,
      durations: durations,
      added: added,
      statuses: statuses,
    );
  }

  // ---------------------------------------------------------------------
  // WHERE

  ({String sql, List<Object?> args}) _where(
    String query,
    LibraryFilter filter,
  ) {
    final clauses = <String>['songs.active = 1'];
    final args = <Object?>[];

    final needle = query.trim();
    if (needle.isNotEmpty) {
      final like = '%$needle%';
      clauses.add(
        '(songs.title LIKE ? OR songs.artist LIKE ? OR songs.album LIKE ?)',
      );
      args.addAll([like, like, like]);
    }

    if (filter.status != LibraryStatusFilter.all) {
      clauses.add(_statusClause(filter.status));
    }

    if (filter.genres.isNotEmpty) {
      final keys = [
        for (final genre in filter.genres) genre.trim().toLowerCase(),
      ]..removeWhere((genre) => genre.isEmpty);
      if (keys.isNotEmpty) {
        final marks = _marks(keys.length);
        clauses.add(
          '(EXISTS ('
          "  SELECT 1 FROM json_each(songs.json, '\$.genres') g "
          '  WHERE LOWER(g.value) IN ($marks)'
          ') OR ('
          "  COALESCE(json_array_length(json_extract(songs.json, '\$.genres')), 0) = 0 "
          "  AND LOWER(COALESCE(json_extract(songs.json, '\$.genre'), '')) "
          '    IN ($marks)'
          '))',
        );
        args.addAll(keys);
        args.addAll(keys);
      }
    }

    if (filter.decades.isNotEmpty) {
      clauses.add(
        '((songs.year / 10) * 10) IN (${_marks(filter.decades.length)})',
      );
      args.addAll(filter.decades);
    }
    if (filter.artists.isNotEmpty) {
      clauses.add('songs.artist IN (${_marks(filter.artists.length)})');
      args.addAll(filter.artists);
    }
    if (filter.sources.isNotEmpty) {
      clauses.add(
        "COALESCE(songs.source_id, 'local') IN (${_marks(filter.sources.length)})",
      );
      args.addAll(filter.sources);
    }
    if (filter.formats.isNotEmpty) {
      clauses.add('songs.format IN (${_marks(filter.formats.length)})');
      args.addAll(filter.formats);
    }
    if (filter.languages.isNotEmpty) {
      clauses.add('songs.language IN (${_marks(filter.languages.length)})');
      args.addAll(filter.languages);
    }

    if (filter.durations.isNotEmpty) {
      final conditions = [
        for (final bucket in filter.durations) _durationClause(bucket),
      ];
      clauses.add('(${conditions.join(' OR ')})');
    }

    if (filter.added.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final conditions = <String>[];
      for (final window in filter.added) {
        final days = switch (window) {
          LibraryAddedWindow.lastWeek => 7,
          LibraryAddedWindow.lastMonth => 30,
          LibraryAddedWindow.lastYear => 365,
          LibraryAddedWindow.older => 0,
        };
        if (window == LibraryAddedWindow.older) {
          conditions.add(
            'songs.date_added > 0 AND songs.date_added < ?',
          );
          args.add(now - const Duration(days: 365).inMilliseconds);
        } else {
          conditions.add('songs.date_added >= ?');
          args.add(now - Duration(days: days).inMilliseconds);
        }
      }
      clauses.add('(${conditions.join(' OR ')})');
    }

    return (sql: 'WHERE ${clauses.join(' AND ')}', args: args);
  }

  static String _statusClause(LibraryStatusFilter status) => switch (status) {
    LibraryStatusFilter.all => '1 = 1',
    LibraryStatusFilter.liked =>
      'EXISTS (SELECT 1 FROM favorites f WHERE f.uri = songs.uri)',
    LibraryStatusFilter.withLyrics =>
      '(songs.has_lyrics = 1 OR EXISTS ('
          '  SELECT 1 FROM smart_lyrics_tasks t '
          "  WHERE t.song_id = json_extract(songs.json, '\$.id') "
          "  AND t.status IN ('done', 'disputed')"
          '))',
    LibraryStatusFilter.withoutLyrics =>
      'NOT (songs.has_lyrics = 1 OR EXISTS ('
          '  SELECT 1 FROM smart_lyrics_tasks t '
          "  WHERE t.song_id = json_extract(songs.json, '\$.id') "
          "  AND t.status IN ('done', 'disputed')"
          '))',
    LibraryStatusFilter.instrumental =>
      'EXISTS (SELECT 1 FROM smart_lyrics_tasks t '
          "  WHERE t.song_id = json_extract(songs.json, '\$.id') "
          "  AND t.status = 'instrumental')",
  };

  static String _durationClause(LibraryDurationBucket bucket) =>
      switch (bucket) {
        LibraryDurationBucket.short => 'songs.duration > 0 AND songs.duration < 120000',
        LibraryDurationBucket.medium =>
          'songs.duration >= 120000 AND songs.duration < 300000',
        LibraryDurationBucket.long =>
          'songs.duration >= 300000 AND songs.duration <= 600000',
        LibraryDurationBucket.epic => 'songs.duration > 600000',
      };

  static String _marks(int count) =>
      List.filled(count, '?').join(', ');

  // ---------------------------------------------------------------------
  // ORDER

  static String _order(LibrarySort sort) {
    final direction = sort.ascending ? 'ASC' : 'DESC';
    return switch (sort.field) {
      LibrarySortField.title =>
        'songs.title_sort COLLATE NOCASE $direction, songs.uri',
      LibrarySortField.addedAt =>
        'CASE WHEN songs.date_added <= 0 THEN 1 ELSE 0 END ASC, '
            'songs.date_added $direction, songs.uri',
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
  // FACETS

  Map<String, int> _genreFacets(LibraryFilter filter) {
    final where = _where('', filter);
    final rows = _db.select(
      'SELECT LOWER(COALESCE(g.value, '
      "  json_extract(songs.json, '\$.genre'))) AS value, "
      'COUNT(DISTINCT songs.uri) AS count '
      'FROM songs '
      "LEFT JOIN json_each(songs.json, '\$.genres') g "
      '${where.sql} '
      'AND COALESCE(g.value, '
      "  json_extract(songs.json, '\$.genre')) IS NOT NULL "
      'AND TRIM(COALESCE(g.value, '
      "  json_extract(songs.json, '\$.genre'))) != '' "
      'GROUP BY value',
      where.args,
    );
    return {
      for (final row in rows)
        if ((row['value'] as String?)?.isNotEmpty ?? false)
          row['value'] as String: (row['count'] as int?) ?? 0,
    };
  }

  Map<int, int> _intFacets(
    LibraryFilter filter,
    String expression, {
    String? extra,
  }) {
    final where = _where('', filter);
    final rows = _db.select(
      'SELECT $expression AS value, COUNT(*) AS count '
      'FROM songs ${where.sql} '
      '${extra == null ? '' : 'AND $extra '}'
      'GROUP BY value',
      where.args,
    );
    return {
      for (final row in rows)
        if (row['value'] is int) row['value'] as int: (row['count'] as int?) ?? 0,
    };
  }

  Map<String, int> _stringFacets(LibraryFilter filter, String expression) {
    final where = _where('', filter);
    final rows = _db.select(
      'SELECT $expression AS value, COUNT(*) AS count '
      'FROM songs ${where.sql} '
      "AND $expression IS NOT NULL AND TRIM($expression) != '' "
      'GROUP BY value',
      where.args,
    );
    return {
      for (final row in rows)
        if ((row['value'] as String?)?.isNotEmpty ?? false)
          row['value'] as String: (row['count'] as int?) ?? 0,
    };
  }

  Map<LibraryDurationBucket, int> _durationFacets(LibraryFilter filter) {
    final where = _where('', filter);
    final rows = _db.select(
      'SELECT CASE '
      '  WHEN songs.duration > 0 AND songs.duration < 120000 THEN ? '
      '  WHEN songs.duration >= 120000 AND songs.duration < 300000 THEN ? '
      '  WHEN songs.duration >= 300000 AND songs.duration <= 600000 THEN ? '
      '  WHEN songs.duration > 600000 THEN ? '
      '  ELSE NULL END AS value, '
      'COUNT(*) AS count '
      'FROM songs ${where.sql} '
      'GROUP BY value',
      [
        for (final bucket in LibraryDurationBucket.values) bucket.name,
        ...where.args,
      ],
    );
    return {
      for (final row in rows)
        if (row['value'] is String)
          LibraryDurationBucket.values.byName(row['value'] as String):
              (row['count'] as int?) ?? 0,
    };
  }

  Map<LibraryAddedWindow, int> _addedFacets(LibraryFilter filter) {
    final where = _where('', filter);
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = _db.select(
      'SELECT CASE '
      '  WHEN songs.date_added >= ? THEN ? '
      '  WHEN songs.date_added >= ? THEN ? '
      '  WHEN songs.date_added >= ? THEN ? '
      '  WHEN songs.date_added > 0 THEN ? '
      '  ELSE NULL END AS value, '
      'COUNT(*) AS count '
      'FROM songs ${where.sql} '
      'GROUP BY value',
      [
        now - const Duration(days: 7).inMilliseconds,
        LibraryAddedWindow.lastWeek.name,
        now - const Duration(days: 30).inMilliseconds,
        LibraryAddedWindow.lastMonth.name,
        now - const Duration(days: 365).inMilliseconds,
        LibraryAddedWindow.lastYear.name,
        LibraryAddedWindow.older.name,
        ...where.args,
      ],
    );
    return {
      for (final row in rows)
        if (row['value'] is String)
          LibraryAddedWindow.values.byName(row['value'] as String):
              (row['count'] as int?) ?? 0,
    };
  }

  Map<LibraryStatusFilter, int> _statusFacets(LibraryFilter filter) {
    final result = <LibraryStatusFilter, int>{};
    for (final status in LibraryStatusFilter.values) {
      final where = _where('', filter.copyWith(status: status));
      final rows = _db.select(
        'SELECT COUNT(*) AS count FROM songs ${where.sql}',
        where.args,
      );
      result[status] = (rows.first['count'] as int?) ?? 0;
    }
    return result;
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
