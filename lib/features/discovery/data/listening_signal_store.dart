import 'dart:convert';

import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';
import 'package:tune/utils/logger.dart';

/// Keeps the aggregates the discover page learns from the player.
///
/// The store is only written when the reader turns local listening history
/// on. It keeps at most [maxTracks] tracks and never writes a title or an
/// artist: a uri and five numbers are enough to rank a recommendation.
class ListeningSignalStore {
  ListeningSignalStore(this._persistence);

  static const String key = 'discovery_listening_v1';
  static const int version = 1;
  static const int maxTracks = 2000;

  final PersistenceService _persistence;

  Map<String, TrackListening> read() {
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
    try {
      await _persistence.remove(key);
    } catch (error, stackTrace) {
      Log.error('清除播放记录失败: $error\n$stackTrace');
    }
  }

  Future<void> _write(Map<String, TrackListening> tracks) async {
    if (tracks.isEmpty) {
      await clear();
      return;
    }

    final pruned = _prune(tracks);
    final uris = pruned.keys.toList()..sort();
    final data = jsonEncode({
      'version': version,
      'tracks': {
        for (final uri in uris) uri: pruned[uri]!.toJson(),
      },
    });
    try {
      await _persistence.setString(key, data);
    } catch (error, stackTrace) {
      Log.error('保存播放记录失败: $error\n$stackTrace');
    }
  }

  /// Keeps the most recently touched tracks when the store grows too large.
  Map<String, TrackListening> _prune(Map<String, TrackListening> tracks) {
    if (tracks.length <= maxTracks) return tracks;
    final entries = tracks.entries.toList()
      ..sort((left, right) {
        final leftAt = left.value.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
        final rightAt = right.value.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
        return rightAt.compareTo(leftAt);
      });
    return {for (final entry in entries.take(maxTracks)) entry.key: entry.value};
  }
}
