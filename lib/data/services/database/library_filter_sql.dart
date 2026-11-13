import 'package:tune/domain/models/content_kind.dart';
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
      kind(filter.kinds),
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

  static const String _live =
      "COALESCE(json_extract(songs.json, '\$.isLiveStream'), 0) = 1";
  static const String _notLive =
      "COALESCE(json_extract(songs.json, '\$.isLiveStream'), 0) != 1";

  /// A station or a recording of one: a live row, or a row of a built-in
  /// instance that declares itself a station.
  static String get radio => '($_live OR ${_declaredOf(ContentKind.radio)})';

  /// Speech: an episode of a show or a chapter of a book.
  ///
  /// A station wins over its source, exactly as [contentKindOfSource] does:
  /// a stream of a feed is a station, not an episode.
  static String get spokenWord =>
      '($_notLive AND NOT ${_declaredOf(ContentKind.radio)} '
      'AND ($_podcastWhere OR $_audiobookWhere))';

  /// The tracks of the chosen content kinds.
  static ({String sql, List<Object?> args})? kind(Set<ContentKind> kinds) {
    if (kinds.isEmpty) return null;
    final conditions = [
      for (final kind in kinds)
        switch (kind) {
          ContentKind.radio => radio,
          ContentKind.music =>
            '($_notLive AND NOT ${_declaredOf(ContentKind.radio)} '
                'AND NOT $_podcastWhere AND NOT $_audiobookWhere)',
          ContentKind.podcast =>
            '($_notLive AND NOT ${_declaredOf(ContentKind.radio)} '
                'AND $_podcastWhere)',
          ContentKind.audiobook =>
            '($_notLive AND NOT ${_declaredOf(ContentKind.radio)} '
                'AND $_audiobookWhere)',
        },
    ];
    return (sql: '(${conditions.join(' OR ')})', args: const []);
  }

  static String get _podcastWhere =>
      '(${_sourcesOf(podcastSourceTypes)} OR '
      '${_declaredOf(ContentKind.podcast)} OR $_localPodcast)';

  static String get _audiobookWhere =>
      '(${_sourcesOf(audiobookSourceTypes)} OR '
      '${_declaredOf(ContentKind.audiobook)} OR $_localAudiobook)';

  /// The built-in instances that publish one kind under an adapter shared
  /// with instances that publish another.
  static String _declaredOf(ContentKind kind) {
    final ids = [
      for (final entry in declaredContentKinds.entries)
        if (entry.value == kind) entry.key,
    ];
    if (ids.isEmpty) return '0';
    return '(${ids.map((id) => "COALESCE(songs.source_id, '') = '$id'").join(' OR ')})';
  }

  static const String _localSource =
      "(COALESCE(songs.source_id, 'local') = 'local')";

  /// The path of a local file, with the separators of every platform written
  /// the same way.
  static const String _localPath =
      "REPLACE(LOWER(COALESCE("
      "json_extract(songs.json, '\$.localPath'), "
      "json_extract(songs.json, '\$.uri'), '')), '\\', '/')";

  static final String _hasAudiobookTag = _tagOf(audiobookGenreTags);
  static final String _hasPodcastTag = _tagOf(podcastGenreTags);

  static String _tagOf(Set<String> tags) {
    final column = [
      for (final tag in tags) "COALESCE(LOWER(songs.genre) LIKE '%$tag%', 0)",
    ].join(' OR ');
    final list = [
      for (final tag in tags) "LOWER(g.value) LIKE '%$tag%'",
    ].join(' OR ');
    return '(($column) OR EXISTS ('
        "SELECT 1 FROM json_each(songs.json, '\$.genres') g "
        'WHERE $list))';
  }

  static String _foldersOf(Set<String> names) => [
    for (final name in names) "$_localPath LIKE '%/$name/%'",
  ].join(' OR ');

  /// A book, read aloud, sitting on this machine.
  ///
  /// The order is the order of confidence of [localContentKindOf]: an
  /// explicit tag first, then the container of a book, then the folder.
  static final String _localAudiobook =
      '($_localSource AND ($_hasAudiobookTag OR '
      '(NOT $_hasPodcastTag AND '
      "($_localPath LIKE '%.m4b' OR ${_foldersOf(audiobookFolderNames)}))))";

  static final String _localPodcast =
      '($_localSource AND NOT $_hasAudiobookTag AND '
      '($_hasPodcastTag OR '
      "(NOT $_localPath LIKE '%.m4b' AND ${_foldersOf(podcastFolderNames)})))";

  /// A built-in instance keeps the id of its type; a created one is
  /// `<type>-<n>`. GLOB reads `_` as a literal, unlike LIKE, so the source
  /// types need no escaping.
  static String _sourcesOf(Iterable<String> types) => [
    for (final type in types)
      "(COALESCE(songs.source_id, '') = '$type' "
          "OR songs.source_id GLOB '$type-[0-9]*')",
  ].join(' OR ');
}
