import 'dart:convert';

import 'package:tune/core/constants/app_preferences_constants.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_session.dart';
import 'package:tune/utils/logger.dart';

/// Reads and writes the part of the playback that survives a restart.
///
/// The queue and the position are stored apart: the position changes every
/// few seconds, and rewriting the whole queue for it would keep the disk busy.
class PlaybackSessionStore {
  final PersistenceService _persistence;

  PlaybackSessionStore(this._persistence);

  /// Writes run one after another, so two position writes cannot overlap and
  /// leave the older value behind.
  Future<void> _writes = Future<void>.value();

  static const queueKey = 'playback_queue_v1';
  static const positionKey = 'playback_position_v1';

  /// The history the queue keeps; the controller applies the same limit.
  static const _maxHistory = 50;

  /// Reads the queue, the cursor, the mode and the last position.
  ///
  /// A missing, empty or broken document is the same as no session: the app
  /// starts with the empty player instead of guessing.
  PlaybackSession? readSession() {
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
        position: _readPosition(
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

  /// The volume of the player.
  ///
  /// It uses the key the old theme service reserved for the volume, so the
  /// two writers keep speaking about the same preference.
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

    final data = jsonEncode({
      'queue': [for (final song in queue) song.toJson()],
      'currentUri': currentUri,
      'playMode': playMode.name,
      'history': history,
    });
    return _serialize(() => _persistence.setString(queueKey, data));
  }

  /// Writes the cursor of the saved position.
  Future<void> savePosition(String currentUri, Duration position) {
    if (currentUri.isEmpty) {
      return clearPosition();
    }
    return _serialize(
      () => _persistence.setString(
        positionKey,
        jsonEncode({'uri': currentUri, 'positionMs': position.inMilliseconds}),
      ),
    );
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
    return _serialize(() async {
      await _persistence.remove(queueKey);
      await _persistence.remove(positionKey);
    });
  }

  Future<void> clearPosition() {
    return _serialize(() => _persistence.remove(positionKey));
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

  /// The saved position, but only when it belongs to the saved track.
  ///
  /// A position at the very end would end the track the moment it starts, so
  /// the last second is treated as "start from the beginning".
  Duration _readPosition(String currentUri, Duration duration) {
    final raw = _persistence.getString(positionKey);
    if (raw == null || raw.trim().isEmpty) return Duration.zero;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['uri'] != currentUri) {
        return Duration.zero;
      }
      final milliseconds = decoded['positionMs'];
      if (milliseconds is! num) return Duration.zero;

      final position = Duration(milliseconds: milliseconds.toInt());
      if (position <= Duration.zero) return Duration.zero;
      if (duration > Duration.zero &&
          position >= duration - const Duration(seconds: 1)) {
        return Duration.zero;
      }
      return position;
    } catch (error, stackTrace) {
      Log.error('读取播放位置失败: $error\n$stackTrace');
      return Duration.zero;
    }
  }
}
