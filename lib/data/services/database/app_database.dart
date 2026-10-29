import 'dart:convert';
import 'dart:io' show Platform;

import 'package:sqlite3/sqlite3.dart';
import 'package:tune/core/utils/text_order.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/album_summary.dart';

/// The library of the app, kept in one SQLite file.
///
/// A JSON document has to be read and written whole: the library of a reader
/// with a hundred thousand tracks would be a hundred megabytes rewritten on
/// every scan. A table writes the rows that changed, and the rows are read
/// back without decoding one giant list.
class AppDatabase {
  AppDatabase(this._db);

  final Database _db;

  /// Opens the database at [path], creating the table the first time.
  static AppDatabase open(String path) =>
      AppDatabase(_prepare(sqlite3.open(path)));

  /// Opens a database that lives only in memory, for tests.
  static AppDatabase inMemory() =>
      AppDatabase(_prepare(sqlite3.openInMemory()));

  /// Creates the table and its indexes when they are not there yet.
  static Database _prepare(Database db) {
    // A write lands on the journal file first; WAL keeps that append in one
    // file and lets a reader run while a write is in flight, so the bursts
    // of writes a session produces (every switch of track, every mark) do
    // not turn into fsyncs on the thread that draws the window.
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA synchronous = NORMAL');
    // Two connections may open the same file (a store that opened its own);
    // a short wait keeps one from failing the other's write.
    db.execute('PRAGMA busy_timeout = 5000');
    db.execute('''
      CREATE TABLE IF NOT EXISTS songs (
        uri TEXT PRIMARY KEY,
        source_id TEXT,
        title TEXT,
        artist TEXT,
        album TEXT,
        date_added INTEGER,
        year INTEGER,
        genre TEXT,
        json TEXT NOT NULL,
        pinned INTEGER NOT NULL DEFAULT 0,
        last_seen INTEGER NOT NULL DEFAULT 0,
        last_played INTEGER,
        play_count INTEGER NOT NULL DEFAULT 0,
        has_lyrics INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_source ON songs(source_id)',
    );
    db.execute('CREATE INDEX IF NOT EXISTS idx_songs_title ON songs(title)');
    // The stratified sample of the accuracy audit (docs/smart-lyrics.md §10):
    // the drawn tracks in one table, the human verdicts in another. The
    // draw only adds rows — a redraw keeps the verdicts of the rounds before.
    db.execute('''
      CREATE TABLE IF NOT EXISTS smart_lyrics_sample (
        uri TEXT PRIMARY KEY,
        layer TEXT NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS smart_lyrics_audit (
        uri TEXT PRIMARY KEY,
        verdict TEXT NOT NULL,
        checked_at INTEGER NOT NULL
      )
    ''');
    // The batch (docs/smart-lyrics.md §7.2): the queue of the tracks the
    // three segments could not bring words for, and the marks a line or a
    // track carries — the marks are the priority the queue runs by.
    db.execute('''
      CREATE TABLE IF NOT EXISTS smart_lyrics_tasks (
        song_id INTEGER PRIMARY KEY,
        uri TEXT NOT NULL,
        status TEXT NOT NULL,
        votes INTEGER NOT NULL DEFAULT 0,
        disputed INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // The marks of the pipeline (docs/smart-lyrics.md §7.4): one row per
    // mark — a line, a whole track, or the name for「不是唱的」. The shape
    // grew from one mark per track to a mark per line within the same
    // release cycle; the old rows held nothing a reader made.
    final markColumns = {
      for (final row in db.select('PRAGMA table_info(smart_lyrics_marks)'))
        row['name'] as String,
    };
    if (markColumns.isNotEmpty && !markColumns.contains('line')) {
      db.execute('DROP TABLE smart_lyrics_marks');
    }
    db.execute('''
      CREATE TABLE IF NOT EXISTS smart_lyrics_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        line INTEGER,
        kind TEXT NOT NULL,
        source TEXT NOT NULL,
        state TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_marks_song '
      'ON smart_lyrics_marks(song_id)',
    );
    db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        uri TEXT PRIMARY KEY,
        added_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS queue (
        position INTEGER PRIMARY KEY,
        uri TEXT NOT NULL,
        json TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS queue_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS listening_signals (
        uri TEXT PRIMARY KEY,
        json TEXT NOT NULL
      )
    ''');
    _migrateColumns(db);
    return db;
  }

  /// Adds the columns an older database does not have yet.
  static void _migrateColumns(Database db) {
    final columns = {
      for (final row in db.select('PRAGMA table_info(songs)'))
        row['name'] as String,
    };
    const additions = {
      'pinned': 'pinned INTEGER NOT NULL DEFAULT 0',
      'last_seen': 'last_seen INTEGER NOT NULL DEFAULT 0',
      'last_played': 'last_played INTEGER',
      'play_count': 'play_count INTEGER NOT NULL DEFAULT 0',
      'year': 'year INTEGER',
      'genre': 'genre TEXT',
      // The fingerprint of a row's facts: a scan that brings the same track
      // back skips the write instead of rewriting the row.
      'facts_hash': 'facts_hash INTEGER NOT NULL DEFAULT 0',
      // Whether the row still belongs to the library the reader sees: a row
      // of a source that is off, or of a file that is gone, does not.
      'active': 'active INTEGER NOT NULL DEFAULT 1',
      // The folded title the rows are ordered by, so a window read from the
      // disk stands in the order the page expects.
      'title_sort': "title_sort TEXT NOT NULL DEFAULT ''",
      // Whether lyrics are known to sit with the track (a tag sheet or a
      // lyrics file next to the audio); the lyrics ledger counts on it.
      'has_lyrics': 'has_lyrics INTEGER NOT NULL DEFAULT 0',
    };
    final added = <String>{};
    for (final entry in additions.entries) {
      if (columns.contains(entry.key)) continue;
      db.execute('ALTER TABLE songs ADD COLUMN ${entry.value}');
      added.add(entry.key);
    }
    // The local files had no source of their own; the built-in local source
    // is named 'local', and every row that belongs to it says so from now on.
    db.execute("UPDATE songs SET source_id = 'local' WHERE source_id IS NULL");
    if (added.contains('title_sort')) _backfillTitleSort(db);
  }

  /// Writes the folded title of every row that misses its sort key.
  ///
  /// An older database ordered its rows the moment they were read; the key is
  /// written once here so the windows that follow read an ordered table.
  /// This runs inside [open], so the one run of it is a one-time pause on the
  /// first start with an older database — a few hundred rows cost nothing, a
  /// library of fifty thousand rows pauses once and never again.
  static void _backfillTitleSort(Database db) {
    final rows = db.select("SELECT uri, title FROM songs WHERE title_sort = ''");
    if (rows.isEmpty) return;
    db.execute('BEGIN');
    try {
      final statement = db.prepare(
        'UPDATE songs SET title_sort = ? WHERE uri = ?',
      );
      try {
        for (final row in rows) {
          statement.execute([
            foldText(row['title'] as String? ?? ''),
            row['uri'] as String,
          ]);
        }
      } finally {
        statement.close();
      }
      db.execute('COMMIT');
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// The tracks the library still holds: the rows that belong to an enabled
  /// source or a file that is still on the disk, in play order.
  List<Song> load() {
    final rows = _db.select(
      'SELECT json FROM songs WHERE active = 1 '
      'ORDER BY title_sort COLLATE NOCASE',
    );
    return _songsFromRows(rows);
  }

  /// Decodes the json column of [rows], skipping the rows that cannot.
  List<Song> _songsFromRows(List<Map<String, Object?>> rows) {
    final songs = <Song>[];
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row['json'] as String);
        if (decoded is! Map<String, dynamic>) continue;
        songs.add(Song.fromMap(decoded));
      } catch (_) {
        // One broken row must not take the whole library down.
      }
    }
    return songs;
  }

  /// The fingerprint of a track's facts: every field the json column holds
  /// takes part. Equal fingerprints mean equal json (a collision misses one
  /// write of one row — harmless), so a scan that brings a track back with
  /// the same facts skips its write instead of rewriting it.
  static int factsHashOf(Song song) {
    final document = Object.hash(
      song.id,
      song.title,
      song.artist,
      song.album,
      song.duration,
      song.uri,
      song.dateAdded,
      song.genre,
      song.year,
      song.bitrate,
      song.sampleRate,
      song.trackNumber,
      song.trackTotal,
      song.discNumber,
      song.totalDisc,
      song.lyrics,
      song.hasLyrics,
      Object.hash(song.language, song.size, song.type, song.albumArtPath),
    );
    final source = Object.hash(
      song.sourceId,
      song.externalId,
      song.streamUrl,
      song.artworkUrl,
      song.isLiveStream,
      song.license,
      song.description,
      song.localPath,
      song.genres == null ? null : Object.hashAll(song.genres!),
      song.performers == null ? null : Object.hashAll(song.performers!),
      song.sourceData == null
          ? null
          : Object.hashAll(
              song.sourceData!.entries.map(
                (entry) => Object.hash(entry.key, entry.value),
              ),
            ),
      song.httpHeaders == null
          ? null
          : Object.hashAll(
              song.httpHeaders!.entries.map(
                (entry) => Object.hash(entry.key, entry.value),
              ),
            ),
    );
    return Object.hash(document, source);
  }

  /// The id a row of [song] belongs to: the local files all belong to the
  /// built-in local source.
  static String _sourceKeyOf(Song song) => song.sourceId ?? 'local';

  /// Upserts [songs] in one transaction.
  ///
  /// The rows outside the batch are left alone: removing a source or a stale
  /// track is an explicit call. A caller that holds one window of a large
  /// library must not erase the rows beyond it.
  void save(List<Song> songs, {Set<String> pinned = const {}}) {
    _db.execute('BEGIN');
    try {
      // The pin and the last seen time follow the scan; the last played time
      // and the play count belong to the player and are left alone.
      final statement = _db.prepare('''
        INSERT INTO songs
          (uri, source_id, title, artist, album, date_added, year, genre,
           json, pinned, last_seen, title_sort, facts_hash, active, has_lyrics)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
        ON CONFLICT(uri) DO UPDATE SET
          source_id = excluded.source_id,
          title = excluded.title,
          artist = excluded.artist,
          album = excluded.album,
          date_added = excluded.date_added,
          year = excluded.year,
          genre = excluded.genre,
          json = excluded.json,
          pinned = excluded.pinned,
          last_seen = excluded.last_seen,
          title_sort = excluded.title_sort,
          facts_hash = excluded.facts_hash,
          active = 1,
          has_lyrics = excluded.has_lyrics
      ''');
      try {
        final seenAt = DateTime.now().millisecondsSinceEpoch;
        for (final song in songs) {
          statement.execute([
            song.uri,
            _sourceKeyOf(song),
            song.title,
            song.artist,
            song.album,
            song.dateAdded,
            song.year,
            song.genre,
            jsonEncode(song.toJson()),
            pinned.contains(song.uri) ? 1 : 0,
            seenAt,
            foldText(song.title),
            factsHashOf(song),
            song.hasLyrics ? 1 : 0,
          ]);
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Merges one batch of scanned tracks into the library.
  ///
  /// A track the library already holds this way is left alone; a track whose
  /// facts changed is rewritten with the earlier "added" time kept; a track
  /// that arrives from another source than the row it names is merged with
  /// that row, so one row says everything both sides knew. Answers how many
  /// rows were written.
  int ingestBatch(List<Song> songs) {
    // A batch can name a uri twice (a file and the copy of its track meet in
    // the same scan); they fold first, so the row is written once.
    final incoming = <String, Song>{};
    for (final song in songs) {
      final known = incoming[song.uri];
      incoming[song.uri] = known == null
          ? song
          : _withFirstSeen(song.mergeWith(known), song.dateAdded, known.dateAdded);
    }

    final existing = {
      for (final row in _existingRows(incoming.keys))
        row['uri'] as String: row,
    };

    var written = 0;
    _db.execute('BEGIN');
    try {
      final statement = _db.prepare('''
        INSERT INTO songs
          (uri, source_id, title, artist, album, date_added, year, genre,
           json, last_seen, title_sort, facts_hash, active, has_lyrics)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
        ON CONFLICT(uri) DO UPDATE SET
          source_id = excluded.source_id,
          title = excluded.title,
          artist = excluded.artist,
          album = excluded.album,
          date_added = excluded.date_added,
          year = excluded.year,
          genre = excluded.genre,
          json = excluded.json,
          last_seen = excluded.last_seen,
          title_sort = excluded.title_sort,
          facts_hash = excluded.facts_hash,
          active = 1,
          has_lyrics = excluded.has_lyrics
      ''');
      try {
        final seenAt = DateTime.now().millisecondsSinceEpoch;
        for (final entry in incoming.entries) {
          final song = entry.value;
          final previous = existing[entry.key];
          final resolved = previous == null
              ? song
              : _withFirstSeen(
                  song,
                  song.dateAdded,
                  (previous['date_added'] as int?) ?? 0,
                );
          // Every row that reaches the disk has the same shape, normalized
          // once: the machine facts of a local file ride on the row, and
          // either side's next scan lands on the stored row unchanged.
          final candidate = mergedCandidate(resolved, previous);
          final previousActive = previous?['active'] as int? ?? 0;
          final previousHash = previous?['facts_hash'] as int? ?? 0;
          if (previousActive == 1 && previousHash == factsHashOf(candidate)) {
            // The scan brought the track back exactly as it is stored: the
            // row is not written, and the library page does not rebuild.
            continue;
          }
          statement.execute([
            candidate.uri,
            _sourceKeyOf(candidate),
            candidate.title,
            candidate.artist,
            candidate.album,
            candidate.dateAdded,
            candidate.year,
            candidate.genre,
            jsonEncode(candidate.toJson()),
            seenAt,
            foldText(candidate.title),
            factsHashOf(candidate),
            candidate.hasLyrics ? 1 : 0,
          ]);
          written++;
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return written;
  }

  /// Reads the rows the batch names, a window of uris at a time: SQLite
  /// refuses more bound parameters than its limit holds.
  List<Map<String, Object?>> _existingRows(Iterable<String> uris) {
    final rows = <Map<String, Object?>>[];
    final batch = uris.toList(growable: false);
    for (var start = 0; start < batch.length; start += 500) {
      final window = batch.skip(start).take(500).toList(growable: false);
      final placeholders = List.filled(window.length, '?').join(', ');
      rows.addAll(
        _db.select(
          'SELECT uri, json, source_id, date_added, facts_hash, active '
          'FROM songs WHERE uri IN ($placeholders)',
          window,
        ),
      );
    }
    return rows;
  }

  /// Keeps the earlier of the two "added" stamps on [song].
  static Song _withFirstSeen(Song song, int incoming, int stored) {
    final earlier = _earlierDate(incoming, stored);
    if (earlier == song.dateAdded) return song;
    return song.copyWith(dateAdded: earlier);
  }

  static int _earlierDate(int left, int right) {
    if (left <= 0) return right;
    if (right <= 0) return left;
    return left < right ? left : right;
  }

  /// Builds the row a scan leaves behind for one of the tracks it brought.
  ///
  /// A track the library has not seen is written as the scan knows it, with
  /// the path of its local file riding on the row. A track the library holds
  /// meets the row it names: what only the stored row knows — the stream
  /// address of its source, the file facts of a fetched copy — is kept, so
  /// the row is the fixed point of either side's next scan. A row that is
  /// only a local file is the scan's own facts alone, so a renamed track is
  /// renamed here as well. Either way the row reaches the disk in one shape,
  /// and the same scan of the same facts writes nothing.
  Song mergedCandidate(Song scanned, Map<String, Object?>? stored) {
    if (stored == null) return _normalized(scanned);
    final storedSong = _storedSongOf(stored);
    if (storedSong == null) return _normalized(scanned);
    // A row that holds no source is the previous shape of this very scan: the
    // scan is the authority of the files it reads. A row a source names may
    // know what the scan does not, so the two fold.
    final sameSource = _sourceKeyOf(storedSong) == _sourceKeyOf(scanned);
    if (sameSource && scanned.hasLocalFile && !storedSong.hasRemoteSource) {
      return _normalized(scanned);
    }
    return _withFirstSeen(
      scanned.mergeWith(storedSong),
      scanned.dateAdded,
      storedSong.dateAdded,
    );
  }

  /// The song the json column of [stored] holds, or null when the column
  /// does not hold one.
  static Song? _storedSongOf(Map<String, Object?> stored) {
    try {
      final decoded = jsonDecode(stored['json'] as String);
      return decoded is Map<String, dynamic> ? Song.fromMap(decoded) : null;
    } catch (_) {
      // A row that cannot be read is replaced by what the scan brought.
      return null;
    }
  }

  /// The one shape a row takes: the path of a local file rides on the row,
  /// so a scan that brings the file again lands on the row it left before.
  static Song _normalized(Song song) => song.mergeWith(song);

  /// Marks the rows the current scan does not cover as outside the library.
  ///
  /// A row of a source that is off, or of a file that no longer sits under
  /// one of the folders the scan reads, is not part of the library the
  /// reader sees: the page reads only the rows that stay marked [active].
  /// The rows are kept, so turning the source back on — or the file coming
  /// back — brings them back with the next scan. Answers how many rows were
  /// marked.
  int deactivateUncovered({
    required Set<String> enabledSourceIds,
    required List<String> localPaths,
  }) {
    var marked = 0;
    _db.execute('BEGIN');
    try {
      if (enabledSourceIds.isEmpty) {
        _db.execute(
          'UPDATE songs SET active = 0 WHERE active = 1',
        );
      } else {
        final placeholders = List.filled(enabledSourceIds.length, '?').join(
          ', ',
        );
        _db.execute(
          'UPDATE songs SET active = 0 WHERE active = 1 '
          'AND source_id NOT IN ($placeholders)',
          enabledSourceIds.toList(growable: false),
        );
      }
      marked += _db.updatedRows;

      // A local row of a folder the scan no longer reads is a file the
      // reader took out of the library. The folders travel as one LIKE
      // clause each: there are a handful of them, not one per file.
      if (localPaths.isNotEmpty) {
        final separator = Platform.isWindows ? r'\' : '/';
        final covered = [
          for (final _ in localPaths) 'uri LIKE ? ESCAPE \'|\'',
        ].join(' OR ');
        final patterns = [
          for (final folder in localPaths)
            '${_likePattern(folder)}$separator%',
        ];
        _db.execute(
          'UPDATE songs SET active = 0 WHERE active = 1 '
          "AND source_id = 'local' AND NOT ($covered)",
          patterns,
        );
        marked += _db.updatedRows;
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return marked;
  }

  /// The folder as a LIKE pattern: the characters the pattern language owns
  /// are kept literal with the escape character.
  static String _likePattern(String folder) {
    final escaped = folder.replaceAll('|', '||');
    return escaped.replaceAll('%', '|%').replaceAll('_', '|_');
  }

  /// Drops the least valuable tracks of every remote source beyond [limit].
  ///
  /// The ranking happens inside the database, so a library of a hundred
  /// thousand tracks is pruned without loading all of them into memory. A
  /// pinned track (a favorite, a queued track) is never dropped; the rest go
  /// by last played, then last seen, then by the time they entered.
  List<String> prune(int limit) {
    if (limit <= 0) return const [];

    const ranking = '''
      SELECT uri,
        ROW_NUMBER() OVER (
          PARTITION BY source_id
          ORDER BY last_played DESC, play_count DESC, last_seen DESC, date_added DESC
        ) AS position
      FROM songs
      WHERE source_id != 'local' AND pinned = 0
    ''';
    final rows = _db.select(
      'SELECT uri FROM ($ranking) WHERE position > ?',
      [limit],
    );
    if (rows.isEmpty) return const [];

    // The delete names the rows through a subquery: a library that drops
    // thousands of tracks at once would exceed the bound parameter limit of
    // SQLite if every uri travelled as one more `?`.
    _db.execute(
      'DELETE FROM songs WHERE uri IN '
      '(SELECT uri FROM ($ranking) WHERE position > ?)',
      [limit],
    );
    return [for (final row in rows) row['uri'] as String];
  }

  /// Marks exactly [ids] as pinned, and every other row as not pinned.
  ///
  /// A window of a large library does not hold every marked track, so the
  /// pin is written to the table as a whole instead of riding on a save.
  /// The ids travel through a temporary table, so a large set of marks does
  /// not become a parameter list that SQLite refuses.
  void syncPinned(Set<String> ids) {
    _db.execute('BEGIN');
    try {
      _db.execute(
        'CREATE TEMP TABLE IF NOT EXISTS tune_pins (uri TEXT PRIMARY KEY)',
      );
      _db.execute('DELETE FROM tune_pins');
      if (ids.isNotEmpty) {
        final statement = _db.prepare(
          'INSERT OR IGNORE INTO tune_pins (uri) VALUES (?)',
        );
        try {
          for (final id in ids) {
            statement.execute([id]);
          }
        } finally {
          statement.close();
        }
      }
      _db.execute('UPDATE songs SET pinned = 0 WHERE pinned = 1');
      _db.execute(
        'UPDATE songs SET pinned = 1 '
        'WHERE uri IN (SELECT uri FROM tune_pins)',
      );
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Notes that a track played, which raises its place in the ranking.
  void markPlayed(String uri) {
    if (uri.isEmpty) return;
    _db.execute(
      'UPDATE songs SET last_played = ?, play_count = play_count + 1 WHERE uri = ?',
      [DateTime.now().millisecondsSinceEpoch, uri],
    );
  }

  /// Reads one window of the library, ordered by the folded title.
  List<Song> page({required int offset, required int limit}) {
    final rows = _db.select(
      'SELECT json FROM songs WHERE active = 1 '
      'ORDER BY title_sort COLLATE NOCASE LIMIT ? OFFSET ?',
      [limit, offset],
    );
    return _songsFromRows(rows);
  }

  /// Reads one window of the tracks that match [query] and [sourceId].
  List<Song> search({
    required String query,
    String? sourceId,
    required int offset,
    required int limit,
  }) {
    final like = '%${query.trim()}%';
    final rows = _db.select(
      '''
      SELECT json FROM songs
      WHERE active = 1
        AND (title LIKE ? OR artist LIKE ? OR album LIKE ?)
        AND (? IS NULL OR source_id = ?)
      ORDER BY title_sort COLLATE NOCASE
      LIMIT ? OFFSET ?
      ''',
      [like, like, like, sourceId, sourceId, limit, offset],
    );
    return _songsFromRows(rows);
  }

  /// How many tracks match [query] and [sourceId].
  int countMatching({required String query, String? sourceId}) {
    final like = '%${query.trim()}%';
    final rows = _db.select(
      '''
      SELECT COUNT(*) AS count FROM songs
      WHERE (title LIKE ? OR artist LIKE ? OR album LIKE ?)
        AND (? IS NULL OR source_id = ?)
      ''',
      [like, like, like, sourceId, sourceId],
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  /// The albums of the library, one row per album and artist.
  List<AlbumSummary> albumSummaries() {
    final rows = _db.select('''
      SELECT album AS name, artist AS artist, COUNT(*) AS count,
             MIN(json) AS sample
      FROM songs
      WHERE album != ''
      GROUP BY album, artist
      ORDER BY album COLLATE NOCASE, artist COLLATE NOCASE
    ''');
    final albums = <AlbumSummary>[];
    for (final row in rows) {
      final name = row['name'] as String? ?? '';
      if (name.isEmpty) continue;
      final artist = row['artist'] as String? ?? '';
      String? coverPath;
      String? coverUrl;
      try {
        final decoded = jsonDecode(row['sample'] as String);
        if (decoded is Map<String, dynamic>) {
          final song = Song.fromMap(decoded);
          coverPath = song.albumArtPath;
          coverUrl = song.artworkUrl;
        }
      } catch (_) {
        // A broken sample only costs the cover of the card.
      }
      albums.add(
        AlbumSummary(
          key: '\${name.trim().toLowerCase()}\u0000'
              '\${artist.trim().toLowerCase()}',
          name: name,
          artist: artist,
          trackCount: row['count'] as int? ?? 0,
          coverPath: coverPath,
          coverUrl: coverUrl,
        ),
      );
    }
    return albums;
  }

  /// The tracks of one album, in the order of the album.
  List<Song> albumSongs(String key) {
    final parts = key.split('\u0000');
    final album = parts.isNotEmpty ? parts[0] : '';
    final artist = parts.length > 1 ? parts[1] : '';
    final rows = _db.select(
      '''
      SELECT json FROM songs
      WHERE lower(trim(album)) = ? AND lower(trim(artist)) = ?
      ORDER BY title COLLATE NOCASE
      ''',
      [album, artist],
    );
    final songs = <Song>[];
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row['json'] as String);
        if (decoded is! Map<String, dynamic>) continue;
        songs.add(Song.fromMap(decoded));
      } catch (_) {
        // One broken row must not take the album down.
      }
    }
    songs.sort((left, right) {
      final disc = (left.discNumber ?? 1).compareTo(right.discNumber ?? 1);
      if (disc != 0) return disc;
      final track = (left.trackNumber ?? 0).compareTo(right.trackNumber ?? 0);
      if (track != 0) return track;
      return compareText(left.title, right.title);
    });
    return songs;
  }

  /// Removes the tracks of one source.
  void removeSource(String sourceId) {
    _db.execute('DELETE FROM songs WHERE source_id = ?', [sourceId]);
  }

  /// The artists of the marked tracks, with how many marks each one holds.
  Map<String, int> favoriteArtistCounts() =>
      _counts('artist', 'artist != \'\'');

  /// The genres of the marked tracks.
  Map<String, int> favoriteGenreCounts() =>
      _counts('genre', 'genre IS NOT NULL AND genre != \'\'');

  /// The albums of the marked tracks.
  Map<String, int> favoriteAlbumCounts() =>
      _counts('album', 'album != \'\'');

  /// The decades of the marked tracks.
  Map<int, int> favoriteDecadeCounts() {
    final rows = _db.select('''
      SELECT (year / 10) * 10 AS decade, COUNT(*) AS count
      FROM songs s JOIN favorites f ON f.uri = s.uri
      WHERE year > 0
      GROUP BY decade
    ''');
    return {
      for (final row in rows) row['decade'] as int: row['count'] as int,
    };
  }

  Map<String, int> _counts(String column, String where) {
    final rows = _db.select('''
      SELECT $column AS key, COUNT(*) AS count
      FROM songs s JOIN favorites f ON f.uri = s.uri
      WHERE $where
      GROUP BY $column
    ''');
    return {
      for (final row in rows) row['key'] as String: row['count'] as int,
    };
  }

  /// The rows the listening aggregates point at, for the taste profile.
  List<TrackSignalRow> listeningRows() {
    final rows = _db.select('''
      SELECT s.artist AS artist, s.genre AS genre, s.year AS year,
             s.album AS album, l.json AS signal
      FROM songs s JOIN listening_signals l ON l.uri = s.uri
    ''');
    return [
      for (final row in rows)
        TrackSignalRow(
          artist: row['artist'] as String? ?? '',
          genre: row['genre'] as String? ?? '',
          year: row['year'] as int? ?? 0,
          album: row['album'] as String? ?? '',
          signal: jsonDecode(row['signal'] as String) as Map<String, dynamic>,
        ),
    ];
  }

  /// The tracks the reader marked with a heart.
  List<String> loadFavorites() {
    final rows = _db.select('SELECT uri FROM favorites ORDER BY added_at');
    return [for (final row in rows) row['uri'] as String];
  }

  /// Replaces the marks with [ids].
  void saveFavorites(Set<String> ids) {
    _db.execute('BEGIN');
    try {
      final existing = {
        for (final row in _db.select('SELECT uri FROM favorites'))
          row['uri'] as String,
      };
      for (final uri in existing.difference(ids)) {
        _db.execute('DELETE FROM favorites WHERE uri = ?', [uri]);
      }
      final statement = _db.prepare(
        'INSERT OR IGNORE INTO favorites (uri, added_at) VALUES (?, ?)',
      );
      try {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final id in ids) {
          if (existing.contains(id)) continue;
          statement.execute([id, now]);
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// The playback queue, in play order.
  List<Song> loadQueue() {
    final rows = _db.select('SELECT json FROM queue ORDER BY position');
    final songs = <Song>[];
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row['json'] as String);
        if (decoded is! Map<String, dynamic>) continue;
        songs.add(Song.fromMap(decoded));
      } catch (_) {
        // One broken row must not take the queue down.
      }
    }
    return songs;
  }

  /// Replaces the queue with [songs].
  void saveQueue(List<Song> songs) {
    _db.execute('BEGIN');
    try {
      _db.execute('DELETE FROM queue');
      final statement = _db.prepare(
        'INSERT INTO queue (position, uri, json) VALUES (?, ?, ?)',
      );
      try {
        for (var index = 0; index < songs.length; index++) {
          final song = songs[index];
          statement.execute([index, song.uri, jsonEncode(song.toJson())]);
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// The small values of the session: the cursor, the mode, the history.
  Map<String, String> loadQueueMeta() {
    final rows = _db.select('SELECT key, value FROM queue_meta');
    return {
      for (final row in rows)
        row['key'] as String: row['value'] as String,
    };
  }

  /// Writes the given keys over whatever is stored, and leaves the others.
  ///
  /// The position is written every few seconds while a track plays; it is
  /// one or two keys of the meta, not the table.
  void saveQueueMeta(Map<String, String> meta) {
    _db.execute('BEGIN');
    try {
      final statement = _db.prepare('''
        INSERT INTO queue_meta (key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''');
      try {
        for (final entry in meta.entries) {
          statement.execute([entry.key, entry.value]);
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Removes the given keys of the meta, and leaves the others.
  void deleteQueueMetaKeys(Iterable<String> keys) {
    _db.execute('BEGIN');
    try {
      final statement = _db.prepare('DELETE FROM queue_meta WHERE key = ?');
      try {
        for (final key in keys) {
          statement.execute([key]);
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void clearQueue() {
    _db.execute('DELETE FROM queue');
    _db.execute('DELETE FROM queue_meta');
  }

  /// The aggregates the discover page learns from the player.
  Map<String, Object?> loadListening() {
    final rows = _db.select('SELECT uri, json FROM listening_signals');
    return {
      for (final row in rows)
        row['uri'] as String: jsonDecode(row['json'] as String),
    };
  }

  /// Writes one record of one track.
  ///
  /// A listen and a skip settle one track at a time; the record is one row,
  /// not a diff over the table.
  void saveListeningEntry(String uri, Map<String, Object?> entry) {
    _db.execute(
      'INSERT OR REPLACE INTO listening_signals (uri, json) VALUES (?, ?)',
      [uri, jsonEncode(entry)],
    );
  }

  /// Drops the records of [uris].
  void deleteListening(Iterable<String> uris) {
    final batch = uris.toList(growable: false);
    for (var start = 0; start < batch.length; start += 500) {
      final window = batch.skip(start).take(500).toList(growable: false);
      final placeholders = List.filled(window.length, '?').join(', ');
      _db.execute(
        'DELETE FROM listening_signals WHERE uri IN ($placeholders)',
        window,
      );
    }
  }

  void saveListening(Map<String, Object?> tracks) {
    _db.execute('BEGIN');
    try {
      final existing = {
        for (final row
            in _db.select('SELECT uri, json FROM listening_signals'))
          row['uri'] as String: row['json'] as String,
      };
      for (final uri in existing.keys.toSet().difference(tracks.keys.toSet())) {
        _db.execute('DELETE FROM listening_signals WHERE uri = ?', [uri]);
      }
      final statement = _db.prepare(
        'INSERT OR REPLACE INTO listening_signals (uri, json) VALUES (?, ?)',
      );
      try {
        for (final entry in tracks.entries) {
          final json = jsonEncode(entry.value);
          if (existing[entry.key] == json) continue;
          statement.execute([entry.key, json]);
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void clearListening() {
    _db.execute('DELETE FROM listening_signals');
  }

  /// Empties the library.
  void clear() {
    _db.execute('DELETE FROM songs');
  }

  /// How many tracks the library holds.
  int count() {
    final rows = _db.select(
      'SELECT COUNT(*) AS count FROM songs WHERE active = 1',
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  /// How many active tracks carry lyrics, and how many the library holds.
  ///
  /// The lyrics ledger of the settings page reads this — one query over the
  /// indexed rows, no library in memory (docs/smart-lyrics.md, M0).
  (int, int) lyricsLedgerCounts() {
    final row = _db
        .select(
          'SELECT COUNT(*) AS total, SUM(has_lyrics) AS with_lyrics '
          'FROM songs WHERE active = 1',
        )
        .first;
    final total = row['total'] as int? ?? 0;
    final withLyrics = row['with_lyrics'] as int? ?? 0;
    return (total, withLyrics);
  }

  /// The facts the accuracy sample classifies on, for the rows that are
  /// still in the library and carry lyrics — the audited share of the
  /// library is its resolved share.
  List<SmartLyricsCandidateRow> resolvedCandidateRows() {
    final rows = _db.select(
      "SELECT uri, title, artist, album, genre, "
      "json_extract(json, '\$.language') AS language "
      'FROM songs WHERE active = 1 AND has_lyrics = 1',
    );
    return [
      for (final row in rows)
        (
          uri: row['uri'] as String,
          title: row['title'] as String? ?? '',
          artist: row['artist'] as String? ?? '',
          album: row['album'] as String? ?? '',
          genre: row['genre'] as String? ?? '',
          language: row['language'] as String?,
        ),
    ];
  }

  /// Writes the drawn tracks; the rows already there stay what they are, so
  /// a redraw neither jumps nor loses a verdict. Answers the count of the
  /// rows the draw added.
  int saveSampleDrawn(List<({String uri, String layer})> entries) {
    var added = 0;
    _db.execute('BEGIN');
    try {
      final statement = _db.prepare(
        'INSERT OR IGNORE INTO smart_lyrics_sample (uri, layer, added_at) '
        'VALUES (?, ?, ?)',
      );
      try {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final entry in entries) {
          statement.execute([entry.uri, entry.layer, now]);
          added += _db.updatedRows;
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return added;
  }

  /// The drawn tracks of one layer, still in the library, with the facts
  /// the verification round shows.
  List<SmartLyricsSampleTrackRow> sampleTracksOf(String layer) {
    final rows = _db.select(
      'SELECT s.uri AS uri, s.title AS title, s.artist AS artist '
      'FROM smart_lyrics_sample sample '
      'JOIN songs s ON s.uri = sample.uri AND s.active = 1 '
      'WHERE sample.layer = ? '
      'ORDER BY sample.added_at, sample.uri',
      [layer],
    );
    return [
      for (final row in rows)
        (
          uri: row['uri'] as String,
          title: row['title'] as String? ?? '',
          artist: row['artist'] as String? ?? '',
        ),
    ];
  }

  /// The account of the sample, layer by layer, over the rows that are
  /// still in the library.
  List<SmartLyricsSampleCountRow> sampleCountRows() {
    final rows = _db.select('''
      SELECT sample.layer AS layer, COUNT(*) AS drawn,
             COUNT(audit.uri) AS checked,
             COALESCE(SUM(audit.verdict = 'correct'), 0) AS correct
      FROM smart_lyrics_sample sample
      JOIN songs ON songs.uri = sample.uri AND songs.active = 1
      LEFT JOIN smart_lyrics_audit audit ON audit.uri = sample.uri
      GROUP BY sample.layer
      ORDER BY sample.layer
    ''');
    return [
      for (final row in rows)
        (
          layer: row['layer'] as String,
          drawn: row['drawn'] as int? ?? 0,
          checked: row['checked'] as int? ?? 0,
          correct: row['correct'] as int? ?? 0,
        ),
    ];
  }

  /// Records — or changes — the human verdict of one drawn track.
  void recordSampleVerdict(String uri, {required bool correct}) {
    _db.execute(
      "INSERT INTO smart_lyrics_audit (uri, verdict, checked_at) "
      "VALUES (?, ?, ?) "
      "ON CONFLICT(uri) DO UPDATE SET "
      "verdict = excluded.verdict, checked_at = excluded.checked_at",
      [uri, correct ? 'correct' : 'incorrect', DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// Puts every active track that carries no lyrics into the queue, and
  /// answers how many rows the press added.
  ///
  /// A scan that finds new gap tracks writes nothing here: the queue moves
  /// when the reader presses the button, never by itself
  /// (docs/smart-lyrics.md §7.2).
  int enqueueMissingTasks({required int now}) {
    var added = 0;
    _db.execute('BEGIN');
    try {
      final statement = _db.prepare(
        "INSERT INTO smart_lyrics_tasks (song_id, uri, status, attempts, updated_at) "
        "SELECT json_extract(json, '\$.id'), uri, 'pending', 0, ? "
        'FROM songs '
        "WHERE active = 1 AND has_lyrics = 0 "
        'AND NOT EXISTS ('
        "  SELECT 1 FROM smart_lyrics_tasks t "
        "  WHERE t.song_id = json_extract(json, '\$.id')"
        ')',
      );
      try {
        statement.execute([now]);
        added = _db.updatedRows;
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (error) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return added;
  }

  /// The gap tracks a scan brought in that are not queued yet.
  int countNewMissingTasks() {
    final row = _db
        .select(
          'SELECT COUNT(*) AS n FROM songs '
          "WHERE active = 1 AND has_lyrics = 0 "
          'AND NOT EXISTS ('
          "  SELECT 1 FROM smart_lyrics_tasks t "
          "  WHERE t.song_id = json_extract(songs.json, '\$.id')"
          ')',
        )
        .first;
    return row['n'] as int? ?? 0;
  }

  /// The next queued track to run, in the order the batch keeps:
  /// a marked track first, then one that was played recently, then one the
  /// reader likes, then the rest — and within one group the song id decides,
  /// so an interrupted run resumes where it stood.
  ({int songId, String uri})? nextPendingTask() {
    final rows = _db.select(
      "SELECT json_extract(songs.json, '\$.id') AS song_id, songs.uri AS uri "
      'FROM songs '
      'WHERE songs.active = 1 '
      'AND EXISTS ('
      '  SELECT 1 FROM smart_lyrics_tasks t '
      "  WHERE t.song_id = json_extract(songs.json, '\$.id') AND t.status = 'pending'"
      ') '
      'ORDER BY CASE '
      "  WHEN EXISTS (SELECT 1 FROM smart_lyrics_marks m "
      "    WHERE m.song_id = json_extract(songs.json, '\$.id') "
      "    AND m.state = 'uncleared') THEN 0 "
      '  WHEN songs.last_played IS NOT NULL THEN 1 '
      '  WHEN EXISTS (SELECT 1 FROM favorites f WHERE f.uri = songs.uri) THEN 2 '
      '  ELSE 3 '
      'END, song_id '
      'LIMIT 1',
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return (songId: row['song_id'] as int, uri: row['uri'] as String);
  }

  /// Marks a task as running; the attempt is counted where it starts.
  void beginTaskRun(int songId, {required int now}) {
    _db.execute(
      'UPDATE smart_lyrics_tasks SET status = ?, attempts = attempts + 1, '
      'updated_at = ? WHERE song_id = ?',
      ['running', now, songId],
    );
  }

  /// Writes how a run ended: the status, what the pool said, and the error
  /// when there was one.
  void setTaskOutcome(
    int songId,
    String status, {
    int votes = 0,
    int disputed = 0,
    String? error,
    required int now,
  }) {
    _db.execute(
      'UPDATE smart_lyrics_tasks SET status = ?, votes = ?, disputed = ?, '
      'last_error = ?, updated_at = ? WHERE song_id = ?',
      [status, votes, disputed, error, now, songId],
    );
  }

  /// The tasks by their status, for the card.
  List<({String status, int count})> taskStatusCounts() {
    final rows = _db.select(
      'SELECT status, COUNT(*) AS n FROM smart_lyrics_tasks GROUP BY status',
    );
    return [
      for (final row in rows)
        (status: row['status'] as String, count: row['n'] as int? ?? 0),
    ];
  }

  /// Puts every failed task back in line for a recheck.
  int requeueFailedTasks({required int now}) {
    _db.execute(
      "UPDATE smart_lyrics_tasks SET status = 'pending', updated_at = ? "
      "WHERE status = 'failed'",
      [now],
    );
    return _db.updatedRows;
  }

  /// The tracks a free check may revive: the failed, the disputed, and the
  /// marked ones — a mark is the reader saying the words are wrong, and
  /// the pool is asked again (docs/smart-lyrics.md §7.4).
  List<Song> leakySongs({required int limit}) {
    final rows = _db.select(
      "SELECT songs.json AS json FROM smart_lyrics_tasks t "
      "JOIN songs ON songs.active = 1 "
      "  AND json_extract(songs.json, '\$.id') = t.song_id "
      "WHERE t.status IN ('failed', 'disputed') "
      'OR EXISTS ('
      "  SELECT 1 FROM smart_lyrics_marks m "
      "  WHERE m.song_id = t.song_id AND m.state = 'uncleared'"
      ') '
      'ORDER BY t.song_id LIMIT ?',
      [limit],
    );
    return [
      for (final row in rows)
        Song.fromMap(jsonDecode(row['json'] as String? ?? '')),
    ];
  }

  /// The track a task names, read back whole from its row.
  Song? songWithId(int id) {
    final rows = _db.select(
      "SELECT json FROM songs WHERE active = 1 AND json_extract(json, '\$.id') = ?",
      [id],
    );
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['json'] as String? ?? '');
    return decoded is Map<String, dynamic> ? Song.fromMap(decoded) : null;
  }

  /// Records a mark on a track — the reader's or the system's; the batch
  /// runs the marked tracks first.
  void addMarkRow({
    required int songId,
    int? line,
    required String kind,
    required String source,
    required int now,
  }) {
    _db.execute(
      'INSERT INTO smart_lyrics_marks '
      '(song_id, line, kind, source, state, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [songId, line, kind, source, 'uncleared', now, now],
    );
  }

  /// Takes back the open marks of a track — [line] when one line is taken
  /// back, [kind] when only one kind is — so undoing the whole-track mark
  /// never touches the flags on its lines.
  void revokeMarkRows(int songId, {int? line, String? kind}) {
    final parts = [
      'song_id = ?',
      "state = 'uncleared'",
      if (line != null) 'line = ?',
      if (kind != null) 'kind = ?',
    ];
    _db.execute(
      'UPDATE smart_lyrics_marks SET state = \'revoked\' WHERE '
      '${parts.join(' AND ')}',
      [songId, ?line, ?kind],
    );
  }

  /// The open marks of a track, in the order they were made.
  List<SmartLyricsMarkRow> openMarkRows(int songId) {
    final rows = _db.select(
      'SELECT id, song_id, line, kind, source, state, created_at, updated_at '
      "FROM smart_lyrics_marks WHERE song_id = ? AND state = 'uncleared' "
      'ORDER BY id',
      [songId],
    );
    return _for(rows);
  }

  /// Whether anything is still on the track's account.
  bool hasOpenMarkRow(int songId) {
    final row = _db.select(
      'SELECT COUNT(*) AS n FROM smart_lyrics_marks '
      "WHERE song_id = ? AND state = 'uncleared'",
      [songId],
    ).first;
    return (row['n'] as int? ?? 0) > 0;
  }

  /// The re-solve worked: the open marks of a track are settled — they
  /// stay on record as resolved, never dangle.
  void resolveMarkRows(int songId, {required int now}) {
    _db.execute(
      "UPDATE smart_lyrics_marks SET state = 'resolved', updated_at = ? "
      "WHERE song_id = ? AND state = 'uncleared'",
      [now, songId],
    );
  }

  /// Puts a track back in line for a re-solve: a mark is the reader saying
  /// the words are wrong, and the pool should hear the song again
  /// (docs/smart-lyrics.md §7.4). A track that carried words has no task
  /// yet — the mark gives it one.
  void requeueSongTask(int songId, {required int now}) {
    _db.execute(
      "INSERT INTO smart_lyrics_tasks (song_id, uri, status, attempts, updated_at) "
      "SELECT json_extract(json, '\$.id'), uri, 'pending', 0, ? "
      "FROM songs WHERE active = 1 AND json_extract(json, '\$.id') = ? "
      'ON CONFLICT(song_id) DO UPDATE SET '
      "status = 'pending', updated_at = excluded.updated_at",
      [now, songId],
    );
  }

  List<SmartLyricsMarkRow> _for(ResultSet rows) => [
    for (final row in rows) _markRowOf(row),
  ];

  SmartLyricsMarkRow _markRowOf(Map<String, Object?> row) => (
    id: row['id'] as int,
    songId: row['song_id'] as int,
    line: row['line'] as int?,
    kind: row['kind'] as String,
    source: row['source'] as String,
    state: row['state'] as String,
    createdAt: row['created_at'] as int? ?? 0,
    updatedAt: row['updated_at'] as int? ?? 0,
  );

  /// The marks of the library, each with the track it belongs to — the
  /// window the management page reads (docs/smart-lyrics.md §7.4).
  List<({SmartLyricsMarkRow mark, Song song})> markRowsWithSongs({
    required int limit,
  }) {
    final rows = _db.select(
      "SELECT songs.json AS json, m.id AS id, m.song_id AS song_id, "
      'm.line AS line, m.kind AS kind, m.source AS source, '
      'm.state AS state, m.created_at AS created_at, '
      'm.updated_at AS updated_at '
      'FROM smart_lyrics_marks m '
      'JOIN songs ON songs.active = 1 '
      "  AND json_extract(songs.json, '\$.id') = m.song_id "
      'ORDER BY m.song_id, m.id LIMIT ?',
      [limit],
    );
    return [
      for (final row in rows)
        (
          mark: _markRowOf(row),
          song: Song.fromMap(jsonDecode(row['json'] as String? ?? '')),
        ),
    ];
  }

  /// Answers a line mark the way the reader's own words answer it.
  void rewordMarkRow(int songId, {required int line, required int now}) {
    _db.execute(
      "UPDATE smart_lyrics_marks SET state = 'reworded', updated_at = ? "
      'WHERE song_id = ? AND line = ? AND state = \'uncleared\'',
      [now, songId, line],
    );
  }

  void close() => _db.close();
}


/// The facts the accuracy sample classifies on, one row of the library.
typedef SmartLyricsCandidateRow =
    ({
      String uri,
      String title,
      String artist,
      String album,
      String genre,
      String? language,
    });

/// One drawn track of the accuracy sample, with the facts the verification
/// round shows.
typedef SmartLyricsSampleTrackRow = ({String uri, String title, String artist});

/// One layer's counts of the accuracy sample.
typedef SmartLyricsSampleCountRow = ({
  String layer,
  int drawn,
  int checked,
  int correct,
});

/// One mark a track carries: a line, the whole track, or the name for
///「不是唱的」— and where it stands.
typedef SmartLyricsMarkRow =
    ({
      int id,
      int songId,
      int? line,
      String kind,
      String source,
      String state,
      int createdAt,
      int updatedAt,
    });

/// One row of the listening aggregates, joined with the facts of its track.
class TrackSignalRow {  final String artist;
  final String genre;
  final int year;
  final String album;
  final Map<String, dynamic> signal;

  const TrackSignalRow({
    required this.artist,
    required this.genre,
    required this.year,
    required this.album,
    required this.signal,
  });
}
