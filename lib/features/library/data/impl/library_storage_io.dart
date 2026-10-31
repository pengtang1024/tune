import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/taste_aggregates.dart';
import 'package:tune/features/library/domain/album_summary.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_sort.dart';
import 'package:tune/features/library/domain/library_album.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/features/library/data/library_document.dart';
import 'package:tune/features/library/data/library_storage.dart';
import 'package:tune/utils/logger.dart';

/// The library storage of a build with a file system.
///
/// The tracks live in a SQLite database, so a library of a hundred thousand
/// tracks is written row by row instead of as one document.
LibraryStorage createLibraryStorage(
  PersistenceService persistence, {
  Future<AppDatabase> Function()? database,
}) => SqliteLibraryStorage(database: database);

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
  Future<int> ingest(List<Song> songs) async {
    // The document is the whole library, so the merge happens in memory: this
    // storage only serves builds and tests that predate the database.
    final stored = {
      for (final song in await load()) song.uri: song,
    };
    final incoming = <String, Song>{
      for (final song in songs) song.uri: song,
    };
    for (final entry in incoming.entries) {
      final known = stored[entry.key];
      stored[entry.key] = known == null
          ? entry.value
          : entry.value.mergeWith(known);
    }
    final merged = stored.values.toList(growable: false);
    final written = merged.length;
    await save(merged);
    return written;
  }

  @override
  Future<int> deactivateUncovered({
    required Set<String> enabledSourceIds,
    required List<String> localPaths,
  }) async {
    // A document cannot hold an inactive row: the rows the scan does not
    // cover are dropped, and the next scan of their source writes them back.
    final coveredPrefixes = [
      for (final folder in localPaths) folder,
    ];
    bool covered(Song song) {
      final sourceId = song.sourceId ?? 'local';
      if (!enabledSourceIds.contains(sourceId)) return false;
      if (sourceId == 'local' && coveredPrefixes.isNotEmpty) {
        return coveredPrefixes.any(
          (folder) =>
              song.uri == folder || song.uri.startsWith('$folder/'),
        );
      }
      return true;
    }

    final kept = (await load()).where(covered).toList(growable: false);
    final marked = (await load()).length - kept.length;
    if (marked > 0) await save(kept);
    return marked;
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
  Future<List<Song>> search({
    required String query,
    String? sourceId,
    required int offset,
    required int limit,
  }) async {
    final all = await _filtered(query, sourceId);
    if (offset >= all.length) return const [];
    return all.sublist(offset, (offset + limit).clamp(0, all.length));
  }

  @override
  Future<int> countMatching({required String query, String? sourceId}) async {
    return (await _filtered(query, sourceId)).length;
  }

  @override
  Future<List<Song>> query({
    required String query,
    required LibraryFilter filter,
    required LibrarySort sort,
    required int offset,
    required int limit,
  }) => search(
    query: query,
    sourceId: filter.sources.length == 1 ? filter.sources.first : null,
    offset: offset,
    limit: limit,
  );

  @override
  Future<int> countQuery({
    required String query,
    required LibraryFilter filter,
  }) => countMatching(
    query: query,
    sourceId: filter.sources.length == 1 ? filter.sources.first : null,
  );

  @override
  Future<LibraryFacets> facets({required LibraryFilter filter}) async =>
      LibraryFacets.empty;

  Future<List<Song>> _filtered(String query, String? sourceId) async {
    final all = await load();
    final needle = query.trim().toLowerCase();
    final filtered = all.where((song) {
      if (sourceId != null && (song.sourceId ?? 'local') != sourceId) {
        return false;
      }
      if (needle.isEmpty) return true;
      return song.title.toLowerCase().contains(needle) ||
          song.artist.toLowerCase().contains(needle) ||
          song.album.toLowerCase().contains(needle);
    }).toList(growable: false);
    filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return filtered;
  }

  @override
  Future<List<AlbumSummary>> albumSummaries() async {
    final albums = libraryAlbumsOf(await load());
    return [
      for (final album in albums)
        AlbumSummary(
          key: album.key,
          name: album.name,
          artist: album.artist,
          trackCount: album.trackCount,
          coverPath: album.coverPath,
          coverUrl: album.coverUrl,
        ),
    ];
  }

  @override
  Future<List<Song>> albumSongs(String key) async {
    final albums = libraryAlbumsOf(await load());
    for (final album in albums) {
      if (album.key == key) return album.songs;
    }
    return const [];
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
  Future<void> syncPinned(Set<String> ids) async {}

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
  SqliteLibraryStorage({
    Future<Directory> Function()? supportDirectory,
    Future<AppDatabase> Function()? database,
  }) : _supportDirectory = supportDirectory,
       _databaseFactory = database;

  static const _fileName = 'library.db';
  static const _folderName = 'library';
  static const _legacyDocument = 'scanned_songs.json';

  final Future<Directory> Function()? _supportDirectory;
  final Future<AppDatabase> Function()? _databaseFactory;

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

    final factory = _databaseFactory;
    final database = factory != null
        ? await factory()
        : AppDatabase.open(path.join((await _directory()).path, _fileName));
    _database = database;
    // A database that the app opens itself owns its migrations; only a
    // database this storage opens on its own adopts the legacy document.
    if (_databaseFactory == null) {
      await _adoptLegacyDocument(database, await _directory());
    }
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
  Future<int> ingest(List<Song> songs) async {
    try {
      final database = await _db();
      // The rows travel to the disk a window at a time. The pause between two
      // windows is a breath for the event loop, so the progress of a scan
      // keeps moving while a library of any size is ingested — this is
      // cooperative scheduling of a bulk write, not a way to hide a state
      // problem from the build.
      var written = 0;
      for (var start = 0; start < songs.length; start += 500) {
        written += database.ingestBatch(
          songs.skip(start).take(500).toList(growable: false),
        );
        if (start + 500 < songs.length) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      return written;
    } catch (error, stackTrace) {
      Log.error('合并音乐库失败: $error\n$stackTrace');
      return 0;
    }
  }

  @override
  Future<int> deactivateUncovered({
    required Set<String> enabledSourceIds,
    required List<String> localPaths,
  }) async {
    try {
      return (await _db()).deactivateUncovered(
        enabledSourceIds: enabledSourceIds,
        localPaths: localPaths,
      );
    } catch (error, stackTrace) {
      Log.error('收窄音乐库失败: $error\n$stackTrace');
      return 0;
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
  Future<List<Song>> search({
    required String query,
    String? sourceId,
    required int offset,
    required int limit,
  }) async {
    try {
      return (await _db()).search(
        query: query,
        sourceId: sourceId,
        offset: offset,
        limit: limit,
      );
    } catch (error, stackTrace) {
      Log.error('搜索音乐库失败: $error\n$stackTrace');
      return const [];
    }
  }

  @override
  Future<int> countMatching({required String query, String? sourceId}) async {
    try {
      return (await _db()).countMatching(query: query, sourceId: sourceId);
    } catch (error, stackTrace) {
      Log.error('统计音乐库搜索结果失败: $error\n$stackTrace');
      return 0;
    }
  }

  @override
  Future<List<Song>> query({
    required String query,
    required LibraryFilter filter,
    required LibrarySort sort,
    required int offset,
    required int limit,
  }) async {
    try {
      return (await _db()).query(
        query: query,
        filter: filter,
        sort: sort,
        offset: offset,
        limit: limit,
      );
    } catch (error, stackTrace) {
      Log.error('读取音乐库筛选窗口失败: $error\n$stackTrace');
      return const [];
    }
  }

  @override
  Future<int> countQuery({
    required String query,
    required LibraryFilter filter,
  }) async {
    try {
      return (await _db()).countQuery(query: query, filter: filter);
    } catch (error, stackTrace) {
      Log.error('统计音乐库筛选结果失败: $error\n$stackTrace');
      return 0;
    }
  }

  @override
  Future<LibraryFacets> facets({required LibraryFilter filter}) async {
    try {
      return (await _db()).facets(filter: filter);
    } catch (error, stackTrace) {
      Log.error('读取音乐库分面计数失败: $error\n$stackTrace');
      return LibraryFacets.empty;
    }
  }

  @override
  Future<List<AlbumSummary>> albumSummaries() async {
    try {
      return (await _db()).albumSummaries();
    } catch (error, stackTrace) {
      Log.error('读取专辑列表失败: $error\n$stackTrace');
      return const [];
    }
  }

  @override
  Future<List<Song>> albumSongs(String key) async {
    try {
      return (await _db()).albumSongs(key);
    } catch (error, stackTrace) {
      Log.error('读取专辑曲目失败: $error\n$stackTrace');
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
  Future<void> syncPinned(Set<String> ids) async {
    try {
      (await _db()).syncPinned(ids);
    } catch (error, stackTrace) {
      Log.error('同步收藏标记失败: $error\n$stackTrace');
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
