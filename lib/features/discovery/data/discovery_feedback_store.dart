import 'dart:convert';

import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/utils/logger.dart';

/// The tracks the reader asked the discover page to recommend less.
///
/// The store keeps one mark per track for 30 days. It is not a black list and
/// it never reaches the library: a dismissed track still plays, still shows
/// in the library and keeps its heart.
class DiscoveryFeedbackStore {
  DiscoveryFeedbackStore(this._persistence);

  static const String key = 'discovery_feedback_v1';
  static const int version = 1;
  static const Duration ttl = Duration(days: 30);

  final PersistenceService _persistence;

  /// The active marks, keyed by the canonical uri of a track.
  Map<String, DateTime> read({DateTime? now}) {
    final raw = _persistence.getString(key);
    if (raw == null || raw.trim().isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      if (decoded['version'] != version) return const {};
      final tracks = decoded['tracks'];
      if (tracks is! Map) return const {};

      final clock = now ?? DateTime.now();
      final result = <String, DateTime>{};
      for (final entry in tracks.entries) {
        final uri = entry.key;
        final value = entry.value;
        if (uri is! String || uri.isEmpty || value is! Map) continue;
        final createdAt = value['createdAt'];
        if (createdAt is! num) continue;
        final at = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());
        if (clock.difference(at) >= ttl) continue;
        result[uri] = at;
      }
      return Map.unmodifiable(result);
    } catch (error, stackTrace) {
      Log.error('读取推荐反馈失败: $error\n$stackTrace');
      return const {};
    }
  }

  /// Marks a track as not interesting.
  Future<void> dismiss(String uri, {DateTime? now}) async {
    if (uri.isEmpty) return;
    final entries = {...read()};
    entries[uri] = now ?? DateTime.now();
    await write(entries);
  }

  /// Takes one mark away.
  Future<void> remove(String uri) async {
    if (uri.isEmpty) return;
    final entries = {...read()}..remove(uri);
    await write(entries);
  }

  Future<void> write(Map<String, DateTime> entries) async {
    if (entries.isEmpty) {
      await clear();
      return;
    }
    final uris = entries.keys.toList()..sort();
    final data = jsonEncode({
      'version': version,
      'tracks': {
        for (final uri in uris)
          uri: {
            'kind': 'notInterested',
            'createdAt': entries[uri]!.millisecondsSinceEpoch,
          },
      },
    });
    try {
      await _persistence.setString(key, data);
    } catch (error, stackTrace) {
      Log.error('保存推荐反馈失败: $error\n$stackTrace');
    }
  }

  Future<void> clear() async {
    try {
      await _persistence.remove(key);
    } catch (error, stackTrace) {
      Log.error('清除推荐反馈失败: $error\n$stackTrace');
    }
  }
}
