import 'dart:convert';

import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/utils/logger.dart';

/// A small map of ids to the time they were marked, with a fixed lifetime.
///
/// The track feedback and the artist feedback have the same shape and the
/// same expiry; one implementation keeps the two files from drifting apart.
class TimedFeedbackStore {
  TimedFeedbackStore({
    required this.persistence,
    required this.key,
    required this.field,
    this.version = 1,
    this.ttl = const Duration(days: 30),
  });

  final PersistenceService persistence;
  final String key;

  /// The name of the map inside the stored document.
  final String field;
  final int version;
  final Duration ttl;

  Map<String, DateTime> read({DateTime? now}) {
    final raw = persistence.getString(key);
    if (raw == null || raw.trim().isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != version) return const {};
      final entries = decoded[field];
      if (entries is! Map) return const {};

      final clock = now ?? DateTime.now();
      final result = <String, DateTime>{};
      for (final entry in entries.entries) {
        final id = entry.key;
        final value = entry.value;
        if (id is! String || id.isEmpty || value is! Map) continue;
        final createdAt = value['createdAt'];
        if (createdAt is! num) continue;
        final at = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());
        if (clock.difference(at) >= ttl) continue;
        result[id] = at;
      }
      return Map.unmodifiable(result);
    } catch (error, stackTrace) {
      Log.error('读取推荐反馈失败: $error\n$stackTrace');
      return const {};
    }
  }

  Future<void> mark(String id, {DateTime? now}) async {
    if (id.isEmpty) return;
    final entries = {...read()}..[id] = now ?? DateTime.now();
    await write(entries);
  }

  Future<void> remove(String id) async {
    if (id.isEmpty) return;
    final entries = {...read()}..remove(id);
    await write(entries);
  }

  Future<void> write(Map<String, DateTime> entries) async {
    if (entries.isEmpty) {
      await clear();
      return;
    }
    final ids = entries.keys.toList()..sort();
    final data = jsonEncode({
      'version': version,
      field: {
        for (final id in ids)
          id: {
            'kind': 'notInterested',
            'createdAt': entries[id]!.millisecondsSinceEpoch,
          },
      },
    });
    try {
      await persistence.setString(key, data);
    } catch (error, stackTrace) {
      Log.error('保存推荐反馈失败: $error\n$stackTrace');
    }
  }

  Future<void> clear() async {
    try {
      await persistence.remove(key);
    } catch (error, stackTrace) {
      Log.error('清除推荐反馈失败: $error\n$stackTrace');
    }
  }
}
