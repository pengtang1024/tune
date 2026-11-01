import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_ledger.dart';

/// Reads the lyrics ledger out of the library database.
///
/// The store owns no rows of its own yet: the baseline of M0 counts the
/// facts the scan wrote (`songs.has_lyrics`). It opens the same file the
/// library and the playback session share, so one database holds the app's
/// index and nothing is copied.
class SmartLyricsLedgerStore {
  SmartLyricsLedgerStore({Future<AppDatabase> Function()? database})
    : _databaseFactory = database;

  final Future<AppDatabase> Function()? _databaseFactory;

  AppDatabase? _database;

  Future<AppDatabase> _db() async {
    final existing = _database;
    if (existing != null) return existing;

    final factory = _databaseFactory;
    final database = factory != null ? await factory() : await _openDefault();
    _database = database;
    return database;
  }

  Future<AppDatabase> _openDefault() async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory(path.join(base.path, 'library'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return AppDatabase.open(path.join(directory.path, 'library.db'));
  }

  /// The ledger as the rows tell it: the whole active library, and the share
  /// of it that carries lyrics.
  ///
  /// A database that cannot be read is not a zero: the error travels, so the
  /// card shows a missing number instead of a lying one.
  Future<SmartLyricsLedger> read() async {
    final (total, withLyrics) = (await _db()).lyricsLedgerCounts();
    return SmartLyricsLedger(total: total, resolved: withLyrics);
  }
}
