import 'dart:async';
import 'dart:convert';

import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/features/smart_lyrics/domain/channel_health.dart';
import 'package:tune/utils/logger.dart';

/// The channel health rings, kept where the other accounts of the sources
/// live — one preference file, newest outcome last (docs/smart-lyrics.md
/// §7.2, M9).
///
/// A channel under the threshold waits out the round: the pool stops
/// asking LRCLIB while it is unreachable, stops uploading to a binary
/// that keeps crashing — the failures count themselves down without a
/// reader tending the list.
class SmartLyricsChannelHealthStore implements ChannelHealthLedger {
  static const healthKey = 'smart_lyrics_channel_health_v1';

  final PersistenceService _persistence;

  final Map<String, List<ChannelOutcome>> _rings = {};
  var _loaded = false;

  SmartLyricsChannelHealthStore(this._persistence);

  @override
  ChannelHealth healthOf(String channelId) {
    _load();
    return ChannelHealth.fromOutcomes(_rings[channelId] ?? const []);
  }

  @override
  void record(String channelId, ChannelOutcome outcome) {
    _load();
    final ring = _rings.putIfAbsent(channelId, () => []);
    ring.add(outcome);
    if (ring.length > ChannelHealth.ringSize) ring.removeAt(0);
    _save();
  }

  void _load() {
    if (_loaded) return;
    _loaded = true;
    final raw = _persistence.getString(healthKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        if (entry.value is List) {
          _rings[entry.key as String] = [
            for (final name in entry.value)
              if (name is String) _outcomeOf(name),
          ];
        }
      }
    } catch (error, stackTrace) {
      Log.error('读取通道健康度失败: $error', stackTrace);
    }
  }

  void _save() {
    final shape = {
      for (final entry in _rings.entries)
        entry.key: [for (final outcome in entry.value) outcome.name],
    };
    unawaited(
      _persistence.setString(healthKey, jsonEncode(shape)).then((ok) {
        if (!ok) Log.error('保存通道健康度失败');
      }),
    );
  }

  static ChannelOutcome _outcomeOf(String name) =>
      ChannelOutcome.values.asNameMap()[name] ?? ChannelOutcome.failure;
}
