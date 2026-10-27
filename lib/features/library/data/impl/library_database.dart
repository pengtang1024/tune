import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:tune/domain/models/song.dart';

/// The library of the app, kept in one SQLite file.
///
/// A JSON document has to be read and written whole: the library of a reader
/// with a hundred thousand tracks would be a hundred megabytes rewritten on
/// every scan. A table writes the rows that changed, and the rows are read
/// back without decoding one giant list.
class LibraryDatabase {
  LibraryDatabase(this._db);

  final Database _db;

  /// Opens the database at [path], creating the table the first time.
  static LibraryDatabase open(String path) =>
      LibraryDatabase(_prepare(sqlite3.open(path)));

  /// Opens a database that lives only in memory, for tests.
  static LibraryDatabase inMemory() =>
      LibraryDatabase(_prepare(sqlite3.openInMemory()));

  /// Creates the table and its indexes when they are not there yet.
  static Database _prepare(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS songs (
        uri TEXT PRIMARY KEY,
        source_id TEXT,
        title TEXT,
        artist TEXT,
        album TEXT,
        date_added INTEGER,
        json TEXT NOT NULL
      )
    ''');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_source ON songs(source_id)',
    );
    db.execute('CREATE INDEX IF NOT EXISTS idx_songs_title ON songs(title)');
    return db;
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
  void save(List<Song> songs) {
    final incoming = {for (final song in songs) song.uri};
    final existing = {
      for (final row in _db.select('SELECT uri FROM songs'))
        row['uri'] as String,
    };

    _db.execute('BEGIN');
    try {
      for (final uri in existing.difference(incoming)) {
        _db.execute('DELETE FROM songs WHERE uri = ?', [uri]);
      }

      final statement = _db.prepare('''
        INSERT OR REPLACE INTO songs
          (uri, source_id, title, artist, album, date_added, json)
        VALUES (?, ?, ?, ?, ?, ?, ?)
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
