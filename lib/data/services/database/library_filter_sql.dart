import 'package:tune/domain/models/library_filter.dart';

/// The filter of the library page, as SQL.
///
/// One clause per group: the page query joins them with AND, and the facet
/// scan asks the same questions per track (does it survive the *other*
/// groups?), so both read the rule from here instead of writing it twice.
class LibraryFilterSql {
  const LibraryFilterSql._();

  /// The tracks that match [query] and every group of [filter].
  static ({String sql, List<Object?> args}) where(
    String query,
    LibraryFilter filter,
  ) {
    final clauses = <String>['songs.active = 1'];
    final args = <Object?>[];
    for (final clause in [
      search(query),
      status(filter.status),
      genre(filter.genres),
      decade(filter.decades),
      artist(filter.artists),
      source(filter.sources),
      format(filter.formats),
      language(filter.languages),
      durationFilter(filter.durations),
      addedFilter(filter.added),
    ]) {
      if (clause == null) continue;
      clauses.add(clause.sql);
      args.addAll(clause.args);
    }
    return (sql: 'WHERE ${clauses.join(' AND ')}', args: args);
  }

  static ({String sql, List<Object?> args})? search(String query) {
    final needle = query.trim();
    if (needle.isEmpty) return null;
    final like = '%$needle%';
    return (
      sql: '(songs.title LIKE ? OR songs.artist LIKE ? OR songs.album LIKE ?)',
      args: [like, like, like],
    );
  }

  static ({String sql, List<Object?> args})? status(LibraryStatusFilter status) {
    final sql = switch (status) {
      LibraryStatusFilter.all => null,
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
    return sql == null ? null : (sql: sql, args: const []);
  }

  static ({String sql, List<Object?> args})? genre(Set<String> genres) {
    final keys = [
      for (final genre in genres) genre.trim().toLowerCase(),
    ]..removeWhere((genre) => genre.isEmpty);
    if (keys.isEmpty) return null;
    final marks = _marks(keys.length);
    return (
      sql: '(EXISTS ('
          "  SELECT 1 FROM json_each(songs.json, '\$.genres') g "
          '  WHERE LOWER(g.value) IN ($marks)'
          ') OR ('
          "  COALESCE(json_array_length(json_extract(songs.json, '\$.genres')), 0) = 0 "
          "  AND LOWER(COALESCE(json_extract(songs.json, '\$.genre'), '')) "
          '    IN ($marks)'
          '))',
      args: [...keys, ...keys],
    );
  }

  static ({String sql, List<Object?> args})? decade(Set<int> decades) {
    if (decades.isEmpty) return null;
    return (
      sql: '((songs.year / 10) * 10) IN (${_marks(decades.length)})',
      args: [...decades],
    );
  }

  static ({String sql, List<Object?> args})? artist(Set<String> artists) {
    if (artists.isEmpty) return null;
    return (
      sql: 'songs.artist IN (${_marks(artists.length)})',
      args: [...artists],
    );
  }

  static ({String sql, List<Object?> args})? source(Set<String> sources) {
    if (sources.isEmpty) return null;
    return (
      sql: "COALESCE(songs.source_id, 'local') IN (${_marks(sources.length)})",
      args: [...sources],
    );
  }

  static ({String sql, List<Object?> args})? format(Set<String> formats) {
    if (formats.isEmpty) return null;
    return (
      sql: 'songs.format IN (${_marks(formats.length)})',
      args: [...formats],
    );
  }

  static ({String sql, List<Object?> args})? language(Set<String> languages) {
    if (languages.isEmpty) return null;
    return (
      sql: 'songs.language IN (${_marks(languages.length)})',
      args: [...languages],
    );
  }

  static ({String sql, List<Object?> args})? durationFilter(
    Set<LibraryDurationBucket> durations,
  ) {
    if (durations.isEmpty) return null;
    final conditions = [
      for (final bucket in durations) duration(bucket),
    ];
    return (sql: '(${conditions.join(' OR ')})', args: const []);
  }

  static ({String sql, List<Object?> args})? addedFilter(
    Set<LibraryAddedWindow> added,
  ) {
    if (added.isEmpty) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final conditions = <String>[];
    final args = <Object?>[];
    for (final window in added) {
      final days = switch (window) {
        LibraryAddedWindow.lastWeek => 7,
        LibraryAddedWindow.lastMonth => 30,
        LibraryAddedWindow.lastYear => 365,
        LibraryAddedWindow.older => 0,
      };
      if (window == LibraryAddedWindow.older) {
        conditions.add('songs.date_added > 0 AND songs.date_added < ?');
        args.add(now - const Duration(days: 365).inMilliseconds);
      } else {
        conditions.add('songs.date_added >= ?');
        args.add(now - Duration(days: days).inMilliseconds);
      }
    }
    return (sql: '(${conditions.join(' OR ')})', args: args);
  }

  static String duration(LibraryDurationBucket bucket) => switch (bucket) {
    LibraryDurationBucket.short =>
      'songs.duration > 0 AND songs.duration < 120000',
    LibraryDurationBucket.medium =>
      'songs.duration >= 120000 AND songs.duration < 300000',
    LibraryDurationBucket.long =>
      'songs.duration >= 300000 AND songs.duration <= 600000',
    LibraryDurationBucket.epic => 'songs.duration > 600000',
  };

  static String _marks(int count) => List.filled(count, '?').join(', ');
}
