import 'package:sqlite3/sqlite3.dart';
import 'package:tune/domain/models/translation_cache.dart';

/// The translation cache and the token ledger, kept in the library database.
///
/// A translation key is the hash of the text, not the track: an album or a
/// station name is translated once however many tracks carry it.
class TranslationTables {
  TranslationTables(this._db);

  final Database _db;

  static void ensureSchema(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS text_translations (
        text_hash TEXT NOT NULL,
        source_text TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        engine TEXT NOT NULL,
        value TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (text_hash, target_lang, engine)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS translation_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        engine TEXT NOT NULL,
        prompt_tokens INTEGER NOT NULL DEFAULT 0,
        completion_tokens INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Map<String, String> readHashes({
    required String targetLanguage,
    required String engine,
  }) {
    final rows = _db.select(
      'SELECT text_hash, value FROM text_translations '
      'WHERE target_lang = ? AND engine = ?',
      [targetLanguage, engine],
    );
    return {
      for (final row in rows)
        row['text_hash'] as String: row['value'] as String,
    };
  }

  /// Writes a whole batch in one transaction; an existing row wins.
  void writeBatch({
    required String targetLanguage,
    required String engine,
    required List<TranslationCacheEntry> entries,
    required int createdAt,
  }) {
    if (entries.isEmpty) return;
    _db.execute('BEGIN');
    try {
      final statement = _db.prepare('''
        INSERT OR IGNORE INTO text_translations
          (text_hash, source_text, target_lang, engine, value, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
      ''');
      try {
        for (final entry in entries) {
          statement.execute([
            entry.hash,
            entry.source,
            targetLanguage,
            engine,
            entry.value,
            createdAt,
          ]);
        }
      } finally {
        statement.close();
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  int count() {
    final rows = _db.select(
      'SELECT COUNT(*) AS total FROM text_translations',
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  void clear() => _db.execute('DELETE FROM text_translations');

  void addUsage({
    required String engine,
    required int promptTokens,
    required int completionTokens,
    required int createdAt,
  }) {
    if (promptTokens == 0 && completionTokens == 0) return;
    _db.execute(
      'INSERT INTO translation_usage '
      '(engine, prompt_tokens, completion_tokens, created_at) '
      'VALUES (?, ?, ?, ?)',
      [engine, promptTokens, completionTokens, createdAt],
    );
  }

  TranslationTokenUsage usageSince(int since) {
    final rows = _db.select(
      'SELECT COALESCE(SUM(prompt_tokens), 0) AS prompt, '
      'COALESCE(SUM(completion_tokens), 0) AS completion '
      'FROM translation_usage WHERE created_at >= ?',
      [since],
    );
    final row = rows.first;
    return TranslationTokenUsage(
      promptTokens: (row['prompt'] as int?) ?? 0,
      completionTokens: (row['completion'] as int?) ?? 0,
    );
  }
}
