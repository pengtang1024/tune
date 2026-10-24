import 'dart:convert';

import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/domain/source_scan_health.dart';
import 'package:tune/utils/logger.dart';

/// Persists source configuration and auto-scan timestamps.
///
/// Only source settings live here; scanned songs stay in [LibraryStorage].
class MusicSourceStore {
  static const configsKey = 'music_sources_v1';
  static const lastScanKey = 'music_source_last_scan_v1';
  static const healthKey = 'music_source_health_v1';

  final PersistenceService _persistence;

  /// In-memory view of the persisted timestamps.
  ///
  /// Sources scan in parallel, so read-modify-write on every markScanned call
  /// would lose updates when two sources finish together.
  Map<String, int>? _scanTimes;
  Future<void> _scanTimesWrite = Future.value();

  MusicSourceStore(this._persistence);

  List<MusicSourceConfig> loadConfigs() {
    final stored = <String, MusicSourceConfig>{};
    final raw = _readSafely(configsKey);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final config = MusicSourceConfig.fromJson(item);
              if (config.id.isNotEmpty) stored[config.id] = config;
            } else if (item is Map) {
              final config = MusicSourceConfig.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (config.id.isNotEmpty) stored[config.id] = config;
            }
          }
        }
      } catch (error, stackTrace) {
        Log.error('读取音源配置失败: $error\n$stackTrace');
      }
    }

    final merged = <MusicSourceConfig>[];
    for (final builtIn in BuiltInMusicSources.defaults) {
      final saved = stored.remove(builtIn.id);
      if (saved == null) {
        merged.add(builtIn);
        continue;
      }

      merged.add(
        builtIn.copyWith(
          enabled: saved.enabled,
          settings: _mergedSettings(builtIn, saved),
          weight: saved.weight,
        ),
      );
    }

    // Preserve future user-imported sources instead of silently dropping them.
    merged.addAll(
      stored.values.where((config) => config.sourceType != retiredPluginType),
    );
    return List.unmodifiable(merged);
  }

  /// The settings of a built-in instance, after the ones the app wrote are
  /// taken away.
  ///
  /// A built-in instance that still carries exactly the settings the app used
  /// to write was never touched by the reader, so the keyword in it goes and
  /// the platform's own list takes its place. An instance the reader changed
  /// keeps its settings.
  Map<String, String> _mergedSettings(
    MusicSourceConfig builtIn,
    MusicSourceConfig saved,
  ) {
    final settings = {...builtIn.settings, ...saved.settings};
    final retired = BuiltInMusicSources.retiredSettingsOf(builtIn.sourceType);
    if (retired.isEmpty || !_isUntouched(saved.settings, retired)) {
      return settings;
    }
    final merged = {...settings};
    for (final key in retired.keys) {
      merged.remove(key);
    }
    return merged;
  }

  /// Whether the settings are exactly the ones the app wrote.
  ///
  /// A keyword may have been written in any language the app speaks, so the
  /// value is looked up in the set of the keywords of that language.
  bool _isUntouched(
    Map<String, String> saved,
    Map<String, Set<String>> retired,
  ) {
    if (saved.length != retired.length) return false;
    for (final entry in retired.entries) {
      final value = saved[entry.key];
      if (value == null || !entry.value.contains(value)) return false;
    }
    return true;
  }

  Future<void> saveConfigs(List<MusicSourceConfig> configs) async {
    final data = jsonEncode(
      configs.map((config) => config.toJson()).toList(growable: false),
    );
    await _persistence.setString(configsKey, data);
  }

  /// The recent scan outcomes of every source, newest last.
  Map<String, SourceScanHealthHistory> loadHealthHistory() {
    final raw = _readSafely(healthKey);
    if (raw == null || raw.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final result = <String, SourceScanHealthHistory>{};
      decoded.forEach((key, value) {
        if (key is String && value is List) {
          result[key] = SourceScanHealthHistory.fromJson(value);
        }
      });
      return result;
    } catch (error, stackTrace) {
      Log.error('读取音源健康历史失败: $error\n$stackTrace');
      return const {};
    }
  }

  Future<void> saveHealthHistory(
    Map<String, SourceScanHealthHistory> history,
  ) async {
    final data = jsonEncode({
      for (final entry in history.entries) entry.key: entry.value.toJson(),
    });
    await _persistence.setString(healthKey, data);
  }

  DateTime? lastScanAt(String sourceId) {
    final value = _cachedScanTimes()[sourceId];
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<void> markScanned(String sourceId, DateTime time) {
    final times = _cachedScanTimes();
    times[sourceId] = time.millisecondsSinceEpoch;

    // Each queued write contains every timestamp marked so far, and the queue
    // keeps an older snapshot from overwriting a newer one.
    final snapshot = Map<String, int>.of(times);
    _scanTimesWrite = _scanTimesWrite.then((_) async {
      try {
        await _persistence.setString(lastScanKey, jsonEncode(snapshot));
      } catch (_) {
        // Timestamp persistence is best-effort; it never invalidates a scan.
      }
    });
    return _scanTimesWrite;
  }

  Map<String, int> _cachedScanTimes() {
    return _scanTimes ??= _loadScanTimes();
  }

  String? _readSafely(String key) {
    try {
      return _persistence.getString(key);
    } catch (_) {
      return null;
    }
  }

  Map<String, int> _loadScanTimes() {
    final raw = _readSafely(lastScanKey);
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, int>{};
      decoded.forEach((key, value) {
        if (key is String && value is num) {
          result[key] = value.toInt();
        }
      });
      return result;
    } catch (error, stackTrace) {
      Log.error('读取音源扫描时间失败: $error\n$stackTrace');
      return {};
    }
  }
}
