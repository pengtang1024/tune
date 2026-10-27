import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:tune/domain/models/song.dart';

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
    // Two connections may open the same file (the library and the session
    // store); a short wait keeps one from failing the other's write.
    db.execute('PRAGMA busy_timeout = 5000');
    db.execute('''
      CREATE TABLE IF NOT EXISTS songs (
        uri TEXT PRIMARY KEY,
        source_id TEXT,
        title TEXT,
        artist TEXT,
        album TEXT,
        date_added INTEGER,
        json TEXT NOT NULL,
        pinned INTEGER NOT NULL DEFAULT 0,
        last_seen INTEGER NOT NULL DEFAULT 0,
        last_played INTEGER,
        play_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_source ON songs(source_id)',
    );
    db.execute('CREATE INDEX IF NOT EXISTS idx_songs_title ON songs(title)');
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
    };
    for (final entry in additions.entries) {
      if (columns.contains(entry.key)) continue;
      db.execute('ALTER TABLE songs ADD COLUMN ${entry.value}');
    }
  }

  /// Every track the library holds.
  List<Song> load() {
    final rows = _db.select('SELECT json FROM songs');
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

  /// Replaces the library with [songs] in one transaction.
  ///
  /// Rows that did not change are left alone, so a scan that adds ten tracks
  /// writes ten rows instead of the whole library.
  void save(List<Song> songs, {Set<String> pinned = const {}}) {
    final seenAt = DateTime.now().millisecondsSinceEpoch;

    _db.execute('BEGIN');
    try {
      // The pin and the last seen time follow the scan; the last played time
      // and the play count belong to the player and are left alone.
      final statement = _db.prepare('''
        INSERT INTO songs
          (uri, source_id, title, artist, album, date_added, json, pinned, last_seen)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(uri) DO UPDATE SET
          source_id = excluded.source_id,
          title = excluded.title,
          artist = excluded.artist,
          album = excluded.album,
          date_added = excluded.date_added,
          json = excluded.json,
          pinned = excluded.pinned,
          last_seen = excluded.last_seen
      ''');
      try {
        for (final song in songs) {
          statement.execute([
            song.uri,
            song.sourceId,
            song.title,
            song.artist,
            song.album,
            song.dateAdded,
            jsonEncode(song.toJson()),
            pinned.contains(song.uri) ? 1 : 0,
            seenAt,
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

  /// Drops the least valuable tracks of every remote source beyond [limit].
  ///
  /// The ranking happens inside the database, so a library of a hundred
  /// thousand tracks is pruned without loading all of them into memory. A
  /// pinned track (a favorite, a queued track) is never dropped; the rest go
  /// by last played, then last seen, then by the time they entered.
  List<String> prune(int limit) {
    if (limit <= 0) return const [];

    final rows = _db.select(
      '''
      SELECT uri FROM (
        SELECT uri,
          ROW_NUMBER() OVER (
            PARTITION BY source_id
            ORDER BY pinned DESC, last_played DESC, last_seen DESC, date_added DESC
          ) AS position
        FROM songs
        WHERE source_id != 'local'
      )
      WHERE position > ?
      ''',
      [limit],
    );
    final removed = [for (final row in rows) row['uri'] as String];
    if (removed.isEmpty) return removed;

    final placeholders = List.filled(removed.length, '?').join(', ');
    _db.execute('DELETE FROM songs WHERE uri IN ($placeholders)', removed);
    return removed;
  }

  /// Notes that a track played, which raises its place in the ranking.
  void markPlayed(String uri) {
    if (uri.isEmpty) return;
    _db.execute(
      'UPDATE songs SET last_played = ?, play_count = play_count + 1 WHERE uri = ?',
      [DateTime.now().millisecondsSinceEpoch, uri],
    );
  }

  /// Reads one window of the library, ordered by title.
  List<Song> page({required int offset, required int limit}) {
    final rows = _db.select(
      'SELECT json FROM songs ORDER BY title COLLATE NOCASE LIMIT ? OFFSET ?',
      [limit, offset],
    );
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

  /// Removes the tracks of one source.
  void removeSource(String sourceId) {
    _db.execute('DELETE FROM songs WHERE source_id = ?', [sourceId]);
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
      _db.execute('DELETE FROM favorites');
      final statement = _db.prepare(
        'INSERT OR REPLACE INTO favorites (uri, added_at) VALUES (?, ?)',
      );
      try {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final id in ids) {
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

  void saveQueueMeta(Map<String, String> meta) {
    _db.execute('BEGIN');
    try {
      _db.execute('DELETE FROM queue_meta');
      final statement = _db.prepare(
        'INSERT INTO queue_meta (key, value) VALUES (?, ?)',
      );
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

  void clearQueue() {
    _db.execute('DELETE FROM queue');
    _db.execute('DELETE FROM queue_meta');
  }

  /// Empties the library.
  void clear() {
    _db.execute('DELETE FROM songs');
  }

  /// How many tracks the library holds.
  int count() {
    final rows = _db.select('SELECT COUNT(*) AS count FROM songs');
    return (rows.first['count'] as int?) ?? 0;
  }

  void close() => _db.close();
}
