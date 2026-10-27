import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';
import 'package:tune/utils/logger.dart';

/// Keeps the aggregates the discover page learns from the player.
///
/// The store is only written when the reader turns local listening history
/// on. It keeps at most [maxTracks] tracks and never writes a title or an
/// artist: a uri and five numbers are enough to rank a recommendation. The
/// records live in SQLite; the old JSON document is read until the database
/// is open.
class ListeningSignalStore {
  ListeningSignalStore(
    this._persistence, {
    Future<Directory> Function()? supportDirectory,
    Future<AppDatabase> Function()? database,
  }) : _supportDirectory = supportDirectory,
       _databaseFactory = database;

  static const String key = 'discovery_listening_v1';
  static const int version = 1;
  static const int maxTracks = 2000;

  final PersistenceService _persistence;
  final Future<Directory> Function()? _supportDirectory;
  final Future<AppDatabase> Function()? _databaseFactory;

  AppDatabase? _database;
  Map<String, TrackListening> _tracks = const {};

  /// Opens the database and reads the records that are already there.
  Future<void> init() async {
    try {
      final factory = _databaseFactory;
      final database = factory != null
          ? await factory()
          : await _openDefault();
      _database = database;

      final stored = database.loadListening();
      if (stored.isEmpty) {
        final legacy = _readJson();
        if (legacy.isNotEmpty) {
          database.saveListening({
            for (final entry in legacy.entries)
              entry.key: entry.value.toJson(),
          });
        }
        _tracks = legacy;
        return;
      }
      _tracks = {
        for (final entry in stored.entries)
          if (entry.value is Map)
            entry.key: TrackListening.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
      };
    } catch (error, stackTrace) {
      Log.error('打开播放记录数据库失败: $error\n$stackTrace');
    }
  }

  Future<AppDatabase> _openDefault() async {
    final base =
        await (_supportDirectory?.call() ?? getApplicationSupportDirectory());
    final directory = Directory(path.join(base.path, 'library'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return AppDatabase.open(path.join(directory.path, 'library.db'));
  }

  Map<String, TrackListening> read() {
    if (_database == null) return _readJson();
    return Map.unmodifiable(_tracks);
  }

  Future<void> recordListen(
    String uri, {
    required Duration listened,
    required bool completed,
    DateTime? at,
  }) async {
    if (uri.isEmpty) return;
    final tracks = {...read()};
    final current = tracks[uri] ?? const TrackListening();
    tracks[uri] = current.recordListen(
      listened: listened,
      completed: completed,
      at: at ?? DateTime.now(),
    );
    await _write(tracks);
  }

  Future<void> recordSkip(String uri, {DateTime? at}) async {
    if (uri.isEmpty) return;
    final tracks = {...read()};
    final current = tracks[uri] ?? const TrackListening();
    tracks[uri] = current.recordSkip(at: at ?? DateTime.now());
    await _write(tracks);
  }

  Future<void> clear() async {
    _tracks = const {};
    final database = _database;
    if (database == null) {
      try {
        await _persistence.remove(key);
      } catch (error, stackTrace) {
        Log.error('清除播放记录失败: $error\n$stackTrace');
      }
      return;
    }
    try {
      database.clearListening();
    } catch (error, stackTrace) {
      Log.error('清除播放记录失败: $error\n$stackTrace');
    }
  }

  Future<void> _write(Map<String, TrackListening> tracks) async {
    if (tracks.isEmpty) {
      await clear();
      return;
    }
    final limited = _trim(tracks);
    _tracks = Map.of(limited);

    final database = _database;
    if (database == null) {
      final data = jsonEncode({
        'version': version,
        'tracks': {
          for (final entry in limited.entries)
            entry.key: entry.value.toJson(),
        },
      });
      try {
        await _persistence.setString(key, data);
      } catch (error, stackTrace) {
        Log.error('保存播放记录失败: $error\n$stackTrace');
      }
      return;
    }

    try {
      database.saveListening({
        for (final entry in limited.entries)
          entry.key: entry.value.toJson(),
      });
    } catch (error, stackTrace) {
      Log.error('保存播放记录失败: $error\n$stackTrace');
    }
  }

  /// Keeps the most recently played records within the ceiling.
  Map<String, TrackListening> _trim(Map<String, TrackListening> tracks) {
    if (tracks.length <= maxTracks) return tracks;
    final sorted = tracks.entries.toList()
      ..sort((a, b) {
        final left = a.value.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
        final right = b.value.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
        return right.compareTo(left);
      });
    return {
      for (final entry in sorted.take(maxTracks)) entry.key: entry.value,
    };
  }

  /// Reads the records of the older JSON document.
  Map<String, TrackListening> _readJson() {
    final raw = _persistence.getString(key);
    if (raw == null || raw.trim().isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != version) return const {};
      final tracks = decoded['tracks'];
      if (tracks is! Map) return const {};

      final result = <String, TrackListening>{};
      for (final entry in tracks.entries) {
        final uri = entry.key;
        final value = entry.value;
        if (uri is! String || uri.isEmpty || value is! Map) continue;
        result[uri] = TrackListening.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
      return Map.unmodifiable(result);
    } catch (error, stackTrace) {
      Log.error('读取播放记录失败: $error\n$stackTrace');
      return const {};
    }
  }
}
