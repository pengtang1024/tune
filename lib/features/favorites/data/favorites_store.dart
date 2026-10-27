import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/utils/logger.dart';

/// Keeps the tracks the user marked with a heart.
///
/// The favorites live in the same SQLite file as the library. A heart is a
/// note of the reader about a track, so it survives a rescan, a restart and
/// a prune; the old JSON list is read once and moved into the table.
class FavoritesStore {
  FavoritesStore(
    this._persistence, {
    Future<Directory> Function()? supportDirectory,
  }) : _supportDirectory = supportDirectory;

  /// The key the older versions kept the addresses under.
  static const String key = 'favorite_tracks';

  final PersistenceService _persistence;
  final Future<Directory> Function()? _supportDirectory;

  Set<String> _ids = const {};
  AppDatabase? _database;

  /// Opens the database and reads the marks that are already there.
  Future<void> init() async {
    try {
      final base =
          await (_supportDirectory?.call() ?? getApplicationSupportDirectory());
      final directory = Directory(path.join(base.path, 'library'));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final database = AppDatabase.open(
        path.join(directory.path, 'library.db'),
      );
      _database = database;

      var stored = database.loadFavorites().toSet();
      if (stored.isEmpty) {
        final legacy = _persistence.getStringList(key) ?? const <String>[];
        final ids = {
          for (final id in legacy)
            if (id.isNotEmpty) id,
        };
        if (ids.isNotEmpty) {
          database.saveFavorites(ids);
          stored = ids;
        }
      }
      _ids = Set.unmodifiable(stored);
    } catch (error, stackTrace) {
      Log.error('读取收藏失败: $error\n$stackTrace');
    }
  }

  /// The tracks that are marked.
  ///
  /// Before the database is open the older JSON list is read, so a build
  /// that starts without a database (or a test) still answers.
  Set<String> read() {
    if (_database != null) return _ids;
    final ids = _persistence.getStringList(key) ?? const <String>[];
    return Set.unmodifiable(ids.where((id) => id.isNotEmpty));
  }

  /// Writes the tracks that are marked.
  Future<void> write(Set<String> ids) async {
    _ids = Set.unmodifiable(ids);
    final database = _database;
    if (database == null) {
      try {
        final sorted = ids.toList(growable: false)..sort();
        await _persistence.setStringList(key, sorted);
      } catch (error, stackTrace) {
        Log.error('保存收藏失败: $error\n$stackTrace');
      }
      return;
    }
    try {
      database.saveFavorites(ids);
    } catch (error, stackTrace) {
      Log.error('保存收藏失败: $error\n$stackTrace');
    }
  }
}
