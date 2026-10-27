import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/taste_aggregates.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/features/library/data/library_document.dart';
import 'package:tune/features/library/data/library_storage.dart';
import 'package:tune/utils/logger.dart';

/// The library storage of a build with a file system.
///
/// The tracks live in a SQLite database, so a library of a hundred thousand
/// tracks is written row by row instead of as one document.
LibraryStorage createLibraryStorage(PersistenceService persistence) =>
    SqliteLibraryStorage();

/// Persists the scanned library as a single JSON document.
///
/// The library is the index the app keeps of the music that is on the disk. It
/// belongs to the app, so it lives in the application support folder next to
/// the other data of the app, and not in a folder of the user.
///
/// This file is intentionally outside the controllers: both scanning and
/// startup loading should go through the same storage boundary.
class FileLibraryStorage implements LibraryStorage {
  FileLibraryStorage({
    Future<Directory> Function()? supportDirectory,
    Future<Directory> Function()? documentsDirectory,
  }) : _supportDirectory = supportDirectory,
       _documentsDirectory = documentsDirectory;

  static const _fileName = 'scanned_songs.json';
  static const _folderName = 'library';

  /// Where the app keeps its data.
  final Future<Directory> Function()? _supportDirectory;

  /// Where the documents folder of the user is, which holds the library of an
  /// older version.
  final Future<Directory> Function()? _documentsDirectory;

  Future<File> _file() async {
    final base =
        await (_supportDirectory?.call() ?? getApplicationSupportDirectory());
    final directory = Directory(path.join(base.path, _folderName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(path.join(directory.path, _fileName));
  }

  @override
  Future<List<Song>> load() async {
    try {
      await _adoptLibraryOfOlderVersion();

      final file = await _file();
      if (!await file.exists()) return const [];

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];

      return decodeLibrary(raw);
    } catch (error, stackTrace) {
      Log.error('读取音乐库失败: $error\n$stackTrace');
      return const [];
    }
  }

  @override
  Future<void> save(List<Song> songs, {Set<String> pinned = const {}}) async {
    try {
      final file = await _file();
      await file.writeAsString(encodeLibrary(songs), flush: true);
    } catch (error, stackTrace) {
      // The library is a cache of what is on disk. A platform without a file
      // system, or a full disk, must not take the player down with it.
      Log.error('保存音乐库失败: $error\n$stackTrace');
    }
  }

  @override
  Future<int> count() async => (await load()).length;

  @override
  Future<List<Song>> page({required int offset, required int limit}) async {
    final all = await load();
    if (offset >= all.length) return const [];
    return all.sublist(offset, (offset + limit).clamp(0, all.length));
  }

  @override
  Future<void> removeSource(String sourceId) async {
    final all = await load();
    final kept = all
        .where((song) => (song.sourceId ?? 'local') != sourceId)
        .toList(growable: false);
    await save(kept);
  }

  @override
  Future<TasteAggregates> tasteAggregates() async => TasteAggregates.empty;

  @override
  Future<List<String>> prune(int limit) async => const [];

  @override
  Future<void> markPlayed(String uri) async {}

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error, stackTrace) {
      Log.error('清空音乐库失败: $error\n$stackTrace');
    }
  }

  /// Moves the library of an older version into the folder of the app.
  ///
  /// An older version kept the library in the documents folder of the user.
  /// That folder belongs to the user, and it is not where the data of the app
  /// belongs, so the library moves the first time the app reads it.
  Future<void> _adoptLibraryOfOlderVersion() async {
    final file = await _file();
    if (await file.exists()) return;

    final older = await _olderFile();
    if (older == null) return;

    await older.copy(file.path);
    await older.delete();
    Log.info('音乐库已迁入应用目录: ${file.path}');
  }

  /// The library of the older version, when there is one.
  Future<File?> _olderFile() async {
    try {
      final documents =
          await (_documentsDirectory?.call() ??
              getApplicationDocumentsDirectory());
      final file = File(path.join(documents.path, _fileName));
      return await file.exists() ? file : null;
    } catch (error) {
      // A platform without a documents folder simply has no older library.
      Log.info('没有旧音乐库可迁移: $error');
      return null;
    }
  }
}

/// The library of a build with a file system, kept in SQLite.
class SqliteLibraryStorage implements LibraryStorage {
  SqliteLibraryStorage({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory;

  static const _fileName = 'library.db';
  static const _folderName = 'library';
  static const _legacyDocument = 'scanned_songs.json';

  final Future<Directory> Function()? _supportDirectory;

  AppDatabase? _database;

  Future<Directory> _directory() async {
    final base =
        await (_supportDirectory?.call() ?? getApplicationSupportDirectory());
    final directory = Directory(path.join(base.path, _folderName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<AppDatabase> _db() async {
    final existing = _database;
    if (existing != null) return existing;

    final directory = await _directory();
    final database = AppDatabase.open(path.join(directory.path, _fileName));
    _database = database;
    await _adoptLegacyDocument(database, directory);
    return database;
  }

  /// Moves the library of the previous version into the database.
  ///
  /// The document is renamed after it is read, so a second start does not
  /// read it again, and the songs it held stay readable if the import fails.
  Future<void> _adoptLegacyDocument(
    AppDatabase database,
    Directory directory,
  ) async {
    if (database.count() > 0) return;

    final document = File(path.join(directory.path, _legacyDocument));
    if (!await document.exists()) return;

    try {
      final songs = decodeLibrary(await document.readAsString());
      if (songs.isEmpty) return;
      database.save(songs);
      await document.rename('${document.path}.migrated');
      Log.info('音乐库已迁入数据库: ${songs.length} 首');
    } catch (error, stackTrace) {
      Log.error('迁移音乐库到数据库失败: $error\n$stackTrace');
    }
  }

  @override
  Future<List<Song>> load() async {
    try {
      return (await _db()).load();
    } catch (error, stackTrace) {
      Log.error('读取音乐库失败: $error\n$stackTrace');
      return const [];
    }
  }

  @override
  Future<void> save(List<Song> songs, {Set<String> pinned = const {}}) async {
    try {
      (await _db()).save(songs, pinned: pinned);
    } catch (error, stackTrace) {
      Log.error('保存音乐库失败: $error\n$stackTrace');
    }
  }

  @override
  Future<int> count() async {
    try {
      return (await _db()).count();
    } catch (error, stackTrace) {
      Log.error('读取音乐库数量失败: $error\n$stackTrace');
      return 0;
    }
  }

  @override
  Future<List<Song>> page({required int offset, required int limit}) async {
    try {
      return (await _db()).page(offset: offset, limit: limit);
    } catch (error, stackTrace) {
      Log.error('读取音乐库分页失败: $error\n$stackTrace');
      return const [];
    }
  }

  @override
  Future<void> removeSource(String sourceId) async {
    try {
      (await _db()).removeSource(sourceId);
    } catch (error, stackTrace) {
      Log.error('移除音源曲目失败: $error\n$stackTrace');
    }
  }

  @override
  Future<TasteAggregates> tasteAggregates() async {
    try {
      final database = await _db();
      return TasteAggregates(
        artists: database.favoriteArtistCounts(),
        genres: database.favoriteGenreCounts(),
        albums: database.favoriteAlbumCounts(),
        decades: database.favoriteDecadeCounts(),
        signals: [
          for (final row in database.listeningRows())
            TasteSignalRow(
              artist: row.artist,
              genre: row.genre,
              album: row.album,
              year: row.year,
              signal: TrackListening.fromJson(row.signal),
            ),
        ],
      );
    } catch (error, stackTrace) {
      Log.error('读取口味聚合失败: $error\n$stackTrace');
      return TasteAggregates.empty;
    }
  }

  @override
  Future<List<String>> prune(int limit) async {
    try {
      return (await _db()).prune(limit);
    } catch (error, stackTrace) {
      Log.error('裁剪音乐库失败: $error\n$stackTrace');
      return const [];
    }
  }

  @override
  Future<void> markPlayed(String uri) async {
    try {
      (await _db()).markPlayed(uri);
    } catch (error, stackTrace) {
      Log.error('记录播放失败: $error\n$stackTrace');
    }
  }

  @override
  Future<void> clear() async {
    try {
      (await _db()).clear();
    } catch (error, stackTrace) {
      Log.error('清空音乐库失败: $error\n$stackTrace');
    }
  }
}
