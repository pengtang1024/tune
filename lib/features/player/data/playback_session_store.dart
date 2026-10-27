import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/core/constants/app_preferences_constants.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_session.dart';
import 'package:tune/utils/logger.dart';

/// Reads and writes the part of the playback that survives a restart.
///
/// The queue lives in SQLite, in the same file as the library; the position
/// is a small value beside it. A build without a database falls back to the
/// older JSON document, so the store works before the database is open.
class PlaybackSessionStore {
  PlaybackSessionStore(
    this._persistence, {
    Future<Directory> Function()? supportDirectory,
    Future<AppDatabase> Function()? database,
  }) : _supportDirectory = supportDirectory,
       _databaseFactory = database;

  final PersistenceService _persistence;
  final Future<Directory> Function()? _supportDirectory;
  final Future<AppDatabase> Function()? _databaseFactory;

  AppDatabase? _database;
  PlaybackSession? _session;

  /// Writes run one after another, so two position writes cannot overlap and
  /// leave the older value behind.
  Future<void> _writes = Future<void>.value();

  static const queueKey = 'playback_queue_v1';
  static const positionKey = 'playback_position_v1';

  /// The history the queue keeps; the controller applies the same limit.
  static const _maxHistory = 50;

  /// Opens the database and reads the session that is already there.
  Future<void> init() async {
    try {
      final factory = _databaseFactory;
      final database = factory != null
          ? await factory()
          : await _openDefault();
      _database = database;

      final queue = database.loadQueue();
      if (queue.isEmpty) {
        final legacy = _parseLegacy();
        if (legacy != null) {
          _session = legacy;
          database.saveQueue(legacy.queue);
          database.saveQueueMeta(_metaOf(legacy));
        }
        return;
      }
      _session = _sessionFromDb(queue, database.loadQueueMeta());
    } catch (error, stackTrace) {
      Log.error('打开播放会话数据库失败: $error\n$stackTrace');
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

  /// Reads the queue, the cursor, the mode and the last position.
  ///
  /// Before the database is open the older JSON document is read, so a build
  /// that starts without one still answers.
  PlaybackSession? readSession() => _session ?? _parseLegacy();

  /// The volume of the player.
  double readVolume() {
    final value = _persistence.getDouble(AppPreferencesConstants.volume);
    if (value == null) return 1.0;
    return value.clamp(0.0, 1.0).toDouble();
  }

  /// Writes the queue and everything but the position.
  Future<void> saveQueue({
    required List<Song> queue,
    required String currentUri,
    required PlayMode playMode,
    required List<String> history,
  }) {
    if (queue.isEmpty || currentUri.isEmpty) {
      return clearSession();
    }

    _session = PlaybackSession(
      queue: queue,
      currentUri: currentUri,
      playMode: playMode,
      // A history entry that is no longer in the queue is dropped here, so
      // the same rule holds before and after the database is open.
      history: _readHistory(history, queue),
    );
    final database = _database;
    if (database == null) {
      return _serialize(
        () => _persistence.setString(queueKey, _encode(_session!)),
      );
    }
    return _serialize(() async {
      database.saveQueue(queue);
      database.saveQueueMeta(_metaOf(_session!));
    });
  }

  /// Writes the cursor of the saved position.
  Future<void> savePosition(String currentUri, Duration position) {
    if (currentUri.isEmpty) {
      return clearPosition();
    }

    final session = _session;
    if (session != null && session.currentUri == currentUri) {
      _session = PlaybackSession(
        queue: session.queue,
        currentUri: currentUri,
        position: _clampPosition(
          position,
          Duration(milliseconds: session.currentSong.duration),
        ),
        playMode: session.playMode,
        history: session.history,
      );
    }
    final database = _database;
    if (database == null) {
      return _serialize(
        () => _persistence.setString(
          positionKey,
          jsonEncode({
            'uri': currentUri,
            'positionMs': position.inMilliseconds,
          }),
        ),
      );
    }
    return _serialize(() async {
      database.saveQueueMeta({
        'positionUri': currentUri,
        'positionMs': '${position.inMilliseconds}',
      });
    });
  }

  Future<void> saveVolume(double volume) {
    return _serialize(
      () => _persistence.setDouble(
        AppPreferencesConstants.volume,
        volume.clamp(0.0, 1.0).toDouble(),
      ),
    );
  }

  /// Drops the queue and the position, but keeps the volume.
  Future<void> clearSession() {
    _session = null;
    final database = _database;
    if (database == null) {
      return _serialize(() async {
        await _persistence.remove(queueKey);
        await _persistence.remove(positionKey);
      });
    }
    return _serialize(() async => database.clearQueue());
  }

  Future<void> clearPosition() {
    _session = _session == null ? null : _zeroPosition(_session!);
    final database = _database;
    if (database == null) {
      return _serialize(() => _persistence.remove(positionKey));
    }
    return _serialize(() async {
      database.deleteQueueMetaKeys(['positionUri', 'positionMs']);
    });
  }

  PlaybackSession _zeroPosition(PlaybackSession session) {
    return PlaybackSession(
      queue: session.queue,
      currentUri: session.currentUri,
      playMode: session.playMode,
      history: session.history,
    );
  }

  Map<String, String> _metaOf(PlaybackSession session) {
    return {
      'currentUri': session.currentUri,
      'playMode': session.playMode.name,
      'history': jsonEncode(session.history),
      'positionUri': session.currentUri,
      'positionMs': '${session.position.inMilliseconds}',
    };
  }

  PlaybackSession? _sessionFromDb(
    List<Song> queue,
    Map<String, String> meta,
  ) {
    if (queue.isEmpty) return null;
    final savedUri = meta['currentUri'] ?? '';
    final currentUri = queue.any((song) => song.uri == savedUri)
        ? savedUri
        : queue.first.uri;
    final song = queue.firstWhere((item) => item.uri == currentUri);

    final positionUri = meta['positionUri'] ?? '';
    final positionMs = int.tryParse(meta['positionMs'] ?? '') ?? 0;
    final position = positionUri == currentUri
        ? _clampPosition(
            Duration(milliseconds: positionMs),
            Duration(milliseconds: song.duration),
          )
        : Duration.zero;

    return PlaybackSession(
      queue: queue,
      currentUri: currentUri,
      position: position,
      playMode: _readMode(meta['playMode']),
      history: _readHistory(_decodeHistory(meta['history']), queue),
    );
  }

  /// Reads the session of the older JSON document.
  PlaybackSession? _parseLegacy() {
    final raw = _persistence.getString(queueKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final queue = _readQueue(decoded['queue']);
      if (queue.isEmpty) return null;

      final savedUri = decoded['currentUri'];
      final currentUri = queue.any((song) => song.uri == savedUri)
          ? savedUri as String
          : queue.first.uri;
      final song = queue.firstWhere((item) => item.uri == currentUri);

      return PlaybackSession(
        queue: queue,
        currentUri: currentUri,
        position: _readLegacyPosition(
          currentUri,
          Duration(milliseconds: song.duration),
        ),
        playMode: _readMode(decoded['playMode']),
        history: _readHistory(decoded['history'], queue),
      );
    } catch (error, stackTrace) {
      Log.error('读取播放会话失败: $error\n$stackTrace');
      return null;
    }
  }

  String _encode(PlaybackSession session) {
    return jsonEncode({
      'queue': [for (final song in session.queue) song.toJson()],
      'currentUri': session.currentUri,
      'playMode': session.playMode.name,
      'history': session.history,
    });
  }

  /// Runs [write] after every write that was asked for before it.
  Future<void> _serialize(Future<void> Function() write) {
    final next = _writes.then((_) => write());
    _writes = next.catchError((Object _) {});
    return next;
  }

  List<Song> _readQueue(Object? value) {
    if (value is! List) return const [];
    final queue = <Song>[];
    final seen = <String>{};
    for (final item in value) {
      if (item is! Map) continue;
      final song = Song.fromMap(Map<String, dynamic>.from(item));
      if (song.uri.isEmpty || !seen.add(song.uri)) continue;
      queue.add(song);
    }
    return List.unmodifiable(queue);
  }

  Object? _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  PlayMode _readMode(Object? value) {
    for (final mode in PlayMode.values) {
      if (mode.name == value) return mode;
    }
    return PlayMode.sequential;
  }

  List<String> _readHistory(Object? value, List<Song> queue) {
    if (value is! List) return const [];
    final known = queue.map((song) => song.uri).toSet();
    final history = <String>[
      for (final uri in value)
        if (uri is String && known.contains(uri)) uri,
    ];
    if (history.length > _maxHistory) {
      history.removeRange(0, history.length - _maxHistory);
    }
    return List.unmodifiable(history);
  }

  Duration _clampPosition(Duration position, Duration duration) {
    if (position <= Duration.zero) return Duration.zero;
    if (duration > Duration.zero &&
        position >= duration - const Duration(seconds: 1)) {
      return Duration.zero;
    }
    return position;
  }

  /// The saved position of the older JSON document.
  Duration _readLegacyPosition(String currentUri, Duration duration) {
    final raw = _persistence.getString(positionKey);
    if (raw == null || raw.trim().isEmpty) return Duration.zero;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['uri'] != currentUri) {
        return Duration.zero;
      }
      final milliseconds = decoded['positionMs'];
      if (milliseconds is! num) return Duration.zero;
      return _clampPosition(
        Duration(milliseconds: milliseconds.toInt()),
        duration,
      );
    } catch (error, stackTrace) {
      Log.error('读取播放位置失败: $error\n$stackTrace');
      return Duration.zero;
    }
  }
}
