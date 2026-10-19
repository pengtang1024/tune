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
import 'package:tune/data/services/music_sources/plugins/music_plugin_repository.dart';
import 'package:tune/data/services/stream_url_resolver.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/utils/logger.dart';

/// Scans every enabled source and isolates failures per source.
///
/// The service is intentionally independent from Riverpod; the library
/// controller owns progress and state, while this class only orchestrates I/O.
class MusicSourceService implements StreamUrlResolver {
  final MusicSourceStore _store;
  final MusicPluginRepository _pluginRepository;
  final Map<String, MusicSourceAdapter> _adapters;

  MusicSourceService({
    required CrossPlatformMusicScanner scanner,
    required MusicSourceStore store,
    Dio? dio,
    MusicPluginRepository? pluginRepository,
  }) : _store = store,
       _pluginRepository = pluginRepository ?? MusicPluginRepository(),
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

  bool supportsConfig(MusicSourceConfig config) {
    if (config.isPlugin) return _pluginRepository.supportsPlugins;
    return supports(config.id);
  }

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

  List<MusicSourceField> fieldsFor(MusicSourceConfig config) {
    if (config.isPlugin) return _pluginRepository.fieldsFor(config);
    return _adapters[config.id]?.configurationFields ?? const [];
  }

  bool isConfigured(MusicSourceConfig config) {
    if (config.isPlugin) return _pluginRepository.isConfigured(config);
    return _adapters[config.id]?.isConfigured(config) ?? false;
  }

  String configurationHint(MusicSourceConfig config) {
    if (config.isPlugin) return '填写搜索关键词后即可扫描插件音源';
    return _adapters[config.id]?.configurationHint ?? '暂不支持该音源';
  }

  Future<MusicSourceAdapter?> _adapterFor(MusicSourceConfig config) async {
    final builtIn = _adapters[config.id];
    if (builtIn != null) return builtIn;
    if (config.isPlugin) return _pluginRepository.adapterFor(config);
    return null;
  }

  /// Asks the owning source for a fresh address of [song].
  ///
  /// Only remote tracks can expire, so local files never reach the source.
  /// Errors are swallowed on purpose: the player reports the failure and the
  /// user decides what to do next.
  @override
  Future<Song?> refresh(Song song) async {
    final sourceId = song.sourceId;
    if (sourceId == null || sourceId.isEmpty) return null;
    if (!song.isRemote) return null;

    try {
      final config = _configFor(sourceId);
      if (config == null) return null;
      final adapter = await _adapterFor(config);
      if (adapter == null) return null;
      return await adapter.refreshStream(config, song);
    } catch (error, stackTrace) {
      Log.error('刷新播放地址失败: $error\n$stackTrace');
      return null;
    }
  }

  /// Looks up the persisted configuration that owns [sourceId].
  MusicSourceConfig? _configFor(String sourceId) {
    for (final config in _store.loadConfigs()) {
      if (config.id == sourceId) return config;
    }
    return null;
  }

  /// Searches every enabled remote source without touching scan timestamps.
  ///
  /// This is intentionally separate from [scanAll]: an on-demand search must
  /// not make the startup auto-scan believe a source has already been refreshed.
  Future<List<SourceScanResult>> search({
    required List<MusicSourceConfig> sources,
    required String query,
    void Function(String sourceId, double progress)? onProgress,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final candidates = sources
        .where((config) => config.enabled && !config.isLocal)
        .toList(growable: false);
    if (candidates.isEmpty) return const [];

    return Future.wait(
      candidates.map((config) async {
        onProgress?.call(config.id, 0);
        final MusicSourceAdapter? adapter;
        try {
          adapter = await _adapterFor(config);
        } catch (error) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.failed,
            message: config.isPlugin
                ? '插件加载失败：${describeSourceError(error)}'
                : describeSourceError(error),
          );
        }
        if (adapter == null) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.failed,
            message: '暂不支持该音源',
          );
        }

        final searchConfig = config.copyWith(
          settings: {...config.settings, 'query': trimmed, 'keywords': trimmed},
        );
        try {
          final result = await adapter.scan(
            MusicSourceScanRequest(
              config: searchConfig,
              onProgress: (progress) => onProgress?.call(config.id, progress),
            ),
          );
          onProgress?.call(config.id, 1);
          return result;
        } catch (error) {
          return failedResult(config.id, error);
        }
      }),
    );
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
    if (!isConfigured(config)) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint(config),
      );
    }

    final MusicSourceAdapter? adapter;
    try {
      adapter = await _adapterFor(config);
    } catch (error) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: config.isPlugin
            ? '插件加载失败：${describeSourceError(error)}'
            : describeSourceError(error),
      );
    }

    if (adapter == null) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: '暂不支持该音源',
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

  Future<void> dispose() => _pluginRepository.dispose();
}
