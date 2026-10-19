import 'dart:async';

import 'package:dio/dio.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/jamendo_source.dart';
import 'package:tune/data/services/music_sources/local_directory_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/netease_cloud_music_source.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/utils/logger.dart';

/// Scans every enabled source and isolates failures per source.
///
/// The service is intentionally independent from Riverpod; the library
/// controller owns progress and state, while this class only orchestrates I/O.
class MusicSourceService {
  final MusicSourceStore _store;
  final Map<String, MusicSourceAdapter> _adapters;

  MusicSourceService({
    required CrossPlatformMusicScanner scanner,
    required MusicSourceStore store,
    Dio? dio,
  }) : _store = store,
       _adapters = {
         'local': LocalDirectorySourceAdapter(scanner),
         'openverse': OpenverseSourceAdapter(dio: dio),
         'jamendo': JamendoSourceAdapter(dio: dio),
         'internet_archive': InternetArchiveSourceAdapter(dio: dio),
         'netease': NeteaseCloudMusicSourceAdapter(dio: dio),
       };

  List<MusicSourceAdapter> get adapters => List.unmodifiable(_adapters.values);

  MusicSourceAdapter? adapterFor(String sourceId) => _adapters[sourceId];

  bool supports(String sourceId) => _adapters.containsKey(sourceId);

  /// Persists scan timestamps after the library controller has saved songs.
  ///
  /// Marking inside [_scanOne] would let a crash leave a "scanned" timestamp
  /// without the corresponding songs, causing the next startup to skip them.
  Future<void> commitSuccessfulScans(Iterable<SourceScanResult> results) async {
    for (final result in results) {
      if (!result.isSuccess) continue;
      try {
        await _store.markScanned(result.sourceId, result.scannedAt);
      } catch (error, stackTrace) {
        Log.error('记录音源扫描时间失败: $error\n$stackTrace');
      }
    }
  }

  List<MusicSourceField> fieldsFor(String sourceId) {
    return _adapters[sourceId]?.configurationFields ?? const [];
  }

  bool isConfigured(MusicSourceConfig config) {
    return _adapters[config.id]?.isConfigured(config) ?? false;
  }

  String configurationHint(MusicSourceConfig config) {
    return _adapters[config.id]?.configurationHint ?? '暂不支持该音源';
  }

  Future<List<SourceScanResult>> scanAll({
    required List<MusicSourceConfig> sources,
    required List<String> localPaths,
    bool respectAutoScanInterval = false,
    void Function(String sourceId, double progress)? onProgress,
  }) async {
    final enabled = sources
        .where((config) => config.enabled)
        .toList(growable: false);
    if (enabled.isEmpty) return const [];

    for (final config in enabled) {
      onProgress?.call(config.id, 0);
    }

    final results = await Future.wait(
      enabled.map(
        (config) => _scanOne(
          config,
          localPaths: localPaths,
          respectAutoScanInterval: respectAutoScanInterval,
          onProgress: (progress) => onProgress?.call(config.id, progress),
        ),
      ),
    );

    for (final config in enabled) {
      onProgress?.call(config.id, 1);
    }
    return results;
  }

  Future<SourceScanResult> _scanOne(
    MusicSourceConfig config, {
    required List<String> localPaths,
    required bool respectAutoScanInterval,
    required void Function(double progress) onProgress,
  }) async {
    final adapter = _adapters[config.id];
    if (adapter == null) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: '暂不支持该音源',
      );
    }

    if (!adapter.isConfigured(config)) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: adapter.configurationHint,
      );
    }

    if (respectAutoScanInterval && adapter.autoScanInterval > Duration.zero) {
      final lastScan = _store.lastScanAt(config.id);
      if (lastScan != null) {
        final age = DateTime.now().difference(lastScan);
        if (age >= Duration.zero && age < adapter.autoScanInterval) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.skipped,
            message: '距上次扫描不足 ${_intervalLabel(adapter.autoScanInterval)}',
          );
        }
      }
    }

    final watch = Stopwatch()..start();
    try {
      final result = await adapter
          .scan(
            MusicSourceScanRequest(
              config: config,
              localPaths: localPaths,
              onProgress: (progress) => onProgress(progress.clamp(0.0, 1.0)),
            ),
          )
          .timeout(adapter.scanTimeout);
      watch.stop();

      return SourceScanResult(
        sourceId: config.id,
        status: result.status,
        songs: result.songs,
        message: result.message,
        scannedAt: result.scannedAt,
        elapsed: watch.elapsed,
      );
    } on TimeoutException {
      watch.stop();
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: '扫描超时（${adapter.scanTimeout.inSeconds}s）',
        elapsed: watch.elapsed,
      );
    } catch (error) {
      watch.stop();
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: describeSourceError(error),
        elapsed: watch.elapsed,
      );
    }
  }

  String _intervalLabel(Duration interval) {
    if (interval.inHours >= 1) return '${interval.inHours} 小时';
    return '${interval.inMinutes} 分钟';
  }
}
