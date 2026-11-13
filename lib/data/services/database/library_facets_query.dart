import 'package:sqlite3/sqlite3.dart';
import 'package:tune/data/services/database/library_filter_sql.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/library_facets.dart';
import 'package:tune/domain/models/library_filter.dart';

/// The counts of every facet group.
///
/// Each group is counted without its own selection, so the other options stay
/// visible while one is chosen. Three statements, not nine: the groups that
/// hold one value per track share a single pass, and the four status counts
/// share one pass over the favorites and lyric tasks. Only the genres still
/// need the `json_each` join, because one track can sit in several of them.
class LibraryFacetsQuery {
  LibraryFacetsQuery(this._db);

  final Database _db;

  LibraryFacets facets({required LibraryFilter filter}) {
    final values = _valueFacets(filter);
    return LibraryFacets(
      genres: _genreFacets(filter.copyWith(genres: const {})),
      decades: values.decades,
      artists: values.artists,
      sources: values.sources,
      languages: values.languages,
      formats: values.formats,
      durations: values.durations,
      added: values.added,
      statuses: _statusFacets(
        filter.copyWith(status: LibraryStatusFilter.all),
      ),
      kinds: values.kinds,
    );
  }

  /// The groups that hold one value per track, counted in one pass.
  ///
  /// A track can fail at most one group and still be counted for that group;
  /// failing two means it is counted nowhere, because no group asks about the
  /// others' selection. So the scan carries one flag per group and the sums
  /// here decide, instead of running one `GROUP BY` per group.
  ({
    Map<int, int> decades,
    Map<String, int> artists,
    Map<String, int> sources,
    Map<String, int> languages,
    Map<String, int> formats,
    Map<LibraryDurationBucket, int> durations,
    Map<LibraryAddedWindow, int> added,
    Map<ContentKind, int> kinds,
  })
  _valueFacets(LibraryFilter filter) {
    final clauses = <_FacetGroup, ({String sql, List<Object?> args})?>{
      _FacetGroup.genres: LibraryFilterSql.genre(filter.genres),
      _FacetGroup.status: LibraryFilterSql.status(filter.status),
      _FacetGroup.decades: LibraryFilterSql.decade(filter.decades),
      _FacetGroup.artists: LibraryFilterSql.artist(filter.artists),
      _FacetGroup.sources: LibraryFilterSql.source(filter.sources),
      _FacetGroup.languages: LibraryFilterSql.language(filter.languages),
      _FacetGroup.formats: LibraryFilterSql.format(filter.formats),
      _FacetGroup.durations: LibraryFilterSql.durationFilter(filter.durations),
      _FacetGroup.added: LibraryFilterSql.addedFilter(filter.added),
      _FacetGroup.kinds: LibraryFilterSql.kind(filter.kinds),
    };
    final columns = <String>[
      'songs.artist AS artist',
      "COALESCE(songs.source_id, 'local') AS source",
      "json_extract(songs.json, '\$.isLiveStream') AS live",
      'songs.language AS language',
      'songs.format AS format',
      'songs.duration AS duration',
      'songs.date_added AS added',
      'songs.year AS year',
    ];
    final args = <Object?>[];
    for (final group in _FacetGroup.values) {
      final clause = clauses[group];
      columns.add('(${clause?.sql ?? '1'}) AS ${group.name}');
      if (clause != null) args.addAll(clause.args);
    }
    final rows = _db.select(
      'SELECT ${columns.join(', ')} FROM songs WHERE songs.active = 1',
      args,
    );

    final decades = <int, int>{};
    final artists = <String, int>{};
    final sources = <String, int>{};
    final languages = <String, int>{};
    final formats = <String, int>{};
    final durations = <LibraryDurationBucket, int>{};
    final added = <LibraryAddedWindow, int>{};
    final kinds = <ContentKind, int>{};
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastWeek = now - const Duration(days: 7).inMilliseconds;
    final lastMonth = now - const Duration(days: 30).inMilliseconds;
    final lastYear = now - const Duration(days: 365).inMilliseconds;
    for (final row in rows) {
      var failures = 0;
      var failedAt = -1;
      for (var index = 0; index < _FacetGroup.values.length; index++) {
        if ((row.columnAt(8 + index) as int?) == 0) {
          failures++;
          failedAt = index;
          if (failures > 1) break;
        }
      }
      if (failures > 1) continue;
      final keepsAll = failures == 0;
      final keepsDecades = keepsAll || failedAt == _FacetGroup.decades.index;
      final keepsArtists = keepsAll || failedAt == _FacetGroup.artists.index;
      final keepsSources = keepsAll || failedAt == _FacetGroup.sources.index;
      final keepsLanguages =
          keepsAll || failedAt == _FacetGroup.languages.index;
      final keepsFormats = keepsAll || failedAt == _FacetGroup.formats.index;
      final keepsDurations =
          keepsAll || failedAt == _FacetGroup.durations.index;
      final keepsAdded = keepsAll || failedAt == _FacetGroup.added.index;
      final keepsKinds = keepsAll || failedAt == _FacetGroup.kinds.index;

      if (keepsArtists) {
        final artist = row.columnAt(0) as String?;
        if (artist != null && artist.trim().isNotEmpty) {
          artists[artist] = (artists[artist] ?? 0) + 1;
        }
      }
      if (keepsSources) {
        final source = row.columnAt(1) as String;
        if (source.trim().isNotEmpty) {
          sources[source] = (sources[source] ?? 0) + 1;
        }
      }
      if (keepsLanguages) {
        final language = row.columnAt(3) as String?;
        if (language != null && language.trim().isNotEmpty) {
          languages[language] = (languages[language] ?? 0) + 1;
        }
      }
      if (keepsFormats) {
        final format = row.columnAt(4) as String?;
        if (format != null && format.trim().isNotEmpty) {
          formats[format] = (formats[format] ?? 0) + 1;
        }
      }
      if (keepsDurations) {
        final bucket = _durationBucketOf(row.columnAt(5) as int?);
        if (bucket != null) durations[bucket] = (durations[bucket] ?? 0) + 1;
      }
      if (keepsAdded) {
        final window = _addedWindowOf(
          row.columnAt(6) as int?,
          lastWeek,
          lastMonth,
          lastYear,
        );
        if (window != null) added[window] = (added[window] ?? 0) + 1;
      }
      if (keepsDecades) {
        final year = row.columnAt(7) as int?;
        if (year != null && year > 0) {
          final decade = (year ~/ 10) * 10;
          decades[decade] = (decades[decade] ?? 0) + 1;
        }
      }
      if (keepsKinds) {
        final kind = contentKindOfSource(
          sourceId: row.columnAt(1) as String?,
          isLiveStream: (row.columnAt(2) as int?) == 1,
        );
        kinds[kind] = (kinds[kind] ?? 0) + 1;
      }
    }
    return (
      decades: decades,
      artists: artists,
      sources: sources,
      languages: languages,
      formats: formats,
      durations: durations,
      added: added,
      kinds: kinds,
    );
  }

  /// One track can carry several genres, so they keep their own join. The
  /// count is per track: a genre that the same track lists twice counts once.
  Map<String, int> _genreFacets(LibraryFilter filter) {
    final where = LibraryFilterSql.where('', filter);
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

  /// The five status counts in one pass: one join to the favorites and one
  /// to the lyric tasks, then four sums over the same rows.
  Map<LibraryStatusFilter, int> _statusFacets(LibraryFilter filter) {
    final where = LibraryFilterSql.where('', filter);
    final rows = _db.select(
      'SELECT COUNT(*) AS total, '
      '  SUM(f.uri IS NOT NULL) AS liked, '
      '  SUM(CASE WHEN songs.has_lyrics = 1 '
      "    OR t.status IN ('done', 'disputed') THEN 1 ELSE 0 END) AS words, "
      "  SUM(CASE WHEN t.status = 'instrumental' THEN 1 ELSE 0 END) "
      '    AS instrumental '
      'FROM songs '
      'LEFT JOIN favorites f ON f.uri = songs.uri '
      'LEFT JOIN smart_lyrics_tasks t '
      "  ON t.song_id = json_extract(songs.json, '\$.id') "
      '${where.sql}',
      where.args,
    );
    final row = rows.first;
    final total = (row['total'] as int?) ?? 0;
    final words = (row['words'] as int?) ?? 0;
    return {
      LibraryStatusFilter.all: total,
      LibraryStatusFilter.liked: (row['liked'] as int?) ?? 0,
      LibraryStatusFilter.withLyrics: words,
      LibraryStatusFilter.withoutLyrics: total - words,
      LibraryStatusFilter.instrumental: (row['instrumental'] as int?) ?? 0,
    };
  }

  static LibraryDurationBucket? _durationBucketOf(int? duration) {
    if (duration == null) return null;
    if (duration > 0 && duration < 120000) return LibraryDurationBucket.short;
    if (duration >= 120000 && duration < 300000) {
      return LibraryDurationBucket.medium;
    }
    if (duration >= 300000 && duration <= 600000) {
      return LibraryDurationBucket.long;
    }
    if (duration > 600000) return LibraryDurationBucket.epic;
    return null;
  }

  static LibraryAddedWindow? _addedWindowOf(
    int? addedAt,
    int lastWeek,
    int lastMonth,
    int lastYear,
  ) {
    if (addedAt == null) return null;
    if (addedAt >= lastWeek) return LibraryAddedWindow.lastWeek;
    if (addedAt >= lastMonth) return LibraryAddedWindow.lastMonth;
    if (addedAt >= lastYear) return LibraryAddedWindow.lastYear;
    if (addedAt > 0) return LibraryAddedWindow.older;
    return null;
  }
}

/// The filter groups, in the order their flags appear in the scan.
enum _FacetGroup {
  genres,
  status,
  decades,
  artists,
  sources,
  languages,
  formats,
  durations,
  added,
  kinds,
}
