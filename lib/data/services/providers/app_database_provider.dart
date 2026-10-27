import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/database/app_database.dart';

/// The one SQLite connection of the app.
///
/// The library, the favorites, the queue and the listening aggregates all
/// live in the same file. One connection keeps their writes from competing
/// for the same lock, and every store that needs the database waits on this
/// future instead of opening a second one.
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final base = await getApplicationSupportDirectory();
  final directory = Directory(path.join(base.path, 'library'));
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return AppDatabase.open(path.join(directory.path, 'library.db'));
});
