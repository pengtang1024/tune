import 'dart:convert';

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
        year INTEGER,
        genre TEXT,
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
          (uri, source_id, title, artist, album, date_added, year, genre,
           json, pinned, last_seen)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
            song.year,
            song.genre,
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
      WHERE (title LIKE ? OR artist LIKE ? OR album LIKE ?)
        AND (? IS NULL OR source_id = ?)
      ORDER BY title COLLATE NOCASE
      LIMIT ? OFFSET ?
      ''',
      [like, like, like, sourceId, sourceId, limit, offset],
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

  /// The aggregates the discover page learns from the player.
  Map<String, Object?> loadListening() {
    final rows = _db.select('SELECT uri, json FROM listening_signals');
    return {
      for (final row in rows)
        row['uri'] as String: jsonDecode(row['json'] as String),
    };
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
    final rows = _db.select('SELECT COUNT(*) AS count FROM songs');
    return (rows.first['count'] as int?) ?? 0;
  }

  void close() => _db.close();
}


/// One row of the listening aggregates, joined with the facts of its track.
class TrackSignalRow {
  final String artist;
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
