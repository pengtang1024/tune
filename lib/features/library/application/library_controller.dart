import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/data/library_storage.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/utils/logger.dart';

final libraryStorageProvider = Provider<LibraryStorage>(
  (ref) => LibraryStorage(),
);

final libraryControllerProvider =
    AsyncNotifierProvider<LibraryController, LibraryState>(
      LibraryController.new,
    );

/// Owns the local and remote library.
///
/// It never starts playback; the UI composes this controller with the playback
/// controller when a row is tapped. Source configuration is owned by
/// [MusicSourcesController], and scan results are merged here so the library
/// remains the single source of truth for songs.
class LibraryController extends AsyncNotifier<LibraryState> {
  late MusicSourceService _sourceService;
  late LibraryStorage _storage;
  bool _disposed = false;
  bool _autoScanStarted = false;
  int _scanGeneration = 0;

  @override
  Future<LibraryState> build() async {
    _disposed = false;
    _autoScanStarted = false;
    _sourceService = ref.read(musicSourceServiceProvider);
    _storage = ref.read(libraryStorageProvider);
    ref.onDispose(() => _disposed = true);

    final songs = await _storage.load();
    return LibraryState(
      songs: List.unmodifiable(songs),
      statusMessage: songs.isEmpty ? null : '${songs.length} 首歌曲',
    );
  }

  LibraryState get _current => state.valueOrNull ?? LibraryState.initial;

  /// Runs once after startup, after the cached library is available.
  Future<void> autoScan(List<String> localPaths) async {
    if (_autoScanStarted) return;
    _autoScanStarted = true;

    await future;
    if (_disposed || !state.hasValue) return;
    await scan(localPaths, auto: true);
  }

  Future<void> scan(List<String> paths, {bool auto = false}) async {
    if (_disposed ||
        !state.hasValue ||
        _current.isScanning ||
        _current.isLoading) {
      return;
    }

    final generation = ++_scanGeneration;
    final scanPaths = paths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toSet()
        .toList(growable: false);

    state = AsyncData(
      _current.copyWith(
        scanStatus: LibraryScanStatus.scanning,
        scanProgress: 0,
        statusMessage: '准备扫描...',
        errorMessage: null,
      ),
    );

    try {
      final sourcesState = await ref.read(
        musicSourcesControllerProvider.future,
      );
      if (_disposed || generation != _scanGeneration) return;

      final enabled = sourcesState.enabled;
      if (enabled.isEmpty) {
        state = AsyncData(
          _current.copyWith(
            scanStatus: LibraryScanStatus.error,
            isLoading: false,
            statusMessage: null,
            errorMessage: '没有启用的音源',
          ),
        );
        return;
      }

      final onlyLocal = enabled.every((source) => source.isLocal);
      if (onlyLocal && scanPaths.isEmpty) {
        state = AsyncData(
          _current.copyWith(
            scanStatus: LibraryScanStatus.error,
            isLoading: false,
            statusMessage: null,
            errorMessage: '没有可扫描的音乐目录',
          ),
        );
        return;
      }

      final progressBySource = <String, double>{
        for (final source in enabled) source.id: 0,
      };
      var lastPercent = -1;

      void reportProgress(String sourceId, double progress) {
        if (_disposed || generation != _scanGeneration) return;
        progressBySource[sourceId] = progress.clamp(0.0, 1.0);
        final total = progressBySource.values.fold<double>(
          0,
          (sum, value) => sum + value,
        );
        final overall = (total / enabled.length).clamp(0.0, 1.0);
        final percent = (overall * 100).round().clamp(0, 100);
        if (percent == lastPercent) return;
        lastPercent = percent;
        state = AsyncData(
          _current.copyWith(
            scanProgress: overall,
            statusMessage: '扫描中 $percent%',
          ),
        );
      }

      final results = await _sourceService.scanAll(
        sources: sourcesState.sources,
        localPaths: scanPaths,
        respectAutoScanInterval: auto,
        onProgress: reportProgress,
      );

      if (_disposed || generation != _scanGeneration) return;

      final songs = _mergeResults(results);
      final summaries = <String, SourceScanSummary>{
        for (final result in results)
          result.sourceId: SourceScanSummary.fromResult(result),
      };

      if (_disposed || generation != _scanGeneration) return;
      final saved = await _saveQuietly(songs);
      if (_disposed || generation != _scanGeneration) return;
      if (saved) {
        await _sourceService.commitSuccessfulScans(results);
        if (_disposed || generation != _scanGeneration) return;
      }

      final successCount = results.where((result) => result.isSuccess).length;
      final failedCount = results
          .where((result) => result.status == SourceScanStatus.failed)
          .length;
      final skippedCount = results
          .where((result) => result.status == SourceScanStatus.skipped)
          .length;
      final needsConfigCount = results
          .where(
            (result) => result.status == SourceScanStatus.needsConfiguration,
          )
          .length;

      state = AsyncData(
        _current.copyWith(
          songs: List.unmodifiable(songs),
          scanStatus: LibraryScanStatus.completed,
          scanProgress: 1,
          isLoading: false,
          statusMessage: _statusMessage(
            results: results,
            songCount: songs.length,
            successCount: successCount,
            failedCount: failedCount,
            skippedCount: skippedCount,
            needsConfigCount: needsConfigCount,
          ),
          errorMessage: successCount == 0 && failedCount > 0
              ? '所有音源扫描失败'
              : null,
          sourceSummaries: Map.unmodifiable(summaries),
        ),
      );
    } catch (error, stackTrace) {
      Log.error('扫描音乐失败: $error\n$stackTrace');
      if (_disposed || generation != _scanGeneration) return;
      state = AsyncData(
        _current.copyWith(
          scanStatus: LibraryScanStatus.error,
          isLoading: false,
          statusMessage: null,
          errorMessage: '扫描失败: $error',
        ),
      );
    }
  }

  void setQuery(String query) {
    if (_disposed || !state.hasValue) return;
    state = AsyncData(_current.copyWith(query: query));
  }

  /// Removes a source's songs immediately, e.g. after deleting a plugin.
  Future<void> dropSource(String sourceId) async {
    if (_disposed || !state.hasValue) return;

    final songs = _current.songs
        .where((song) => (song.sourceId ?? 'local') != sourceId)
        .toList(growable: false);
    final summaries = Map<String, SourceScanSummary>.of(
      _current.sourceSummaries,
    )..remove(sourceId);

    state = AsyncData(
      _current.copyWith(
        songs: List.unmodifiable(songs),
        sourceSummaries: Map.unmodifiable(summaries),
        sourceFilter: _current.sourceFilter == sourceId
            ? null
            : _current.sourceFilter,
      ),
    );
    await _saveQuietly(songs);
  }

  void setSourceFilter(String? sourceId) {
    if (_disposed || !state.hasValue) return;
    final normalized = sourceId?.trim();
    state = AsyncData(
      _current.copyWith(
        sourceFilter: normalized == null || normalized.isEmpty
            ? null
            : normalized,
      ),
    );
  }

  Future<void> clearLibrary() async {
    if (_disposed || !state.hasValue) return;
    _scanGeneration++;
    state = AsyncData(_current.copyWith(isLoading: true, errorMessage: null));
    try {
      await _storage.clear();
      if (_disposed) return;
      state = const AsyncData(LibraryState.initial);
    } catch (error, stackTrace) {
      Log.error('清空音乐库失败: $error\n$stackTrace');
      if (_disposed) return;
      state = AsyncData(
        _current.copyWith(isLoading: false, errorMessage: '清空音乐库失败: $error'),
      );
    }
  }

  /// Successful sources replace their previous songs. Failed or skipped
  /// sources keep their cached songs instead of disappearing from the library.
  List<Song> _mergeResults(List<SourceScanResult> results) {
    final previousBySource = <String, List<Song>>{};
    for (final song in _current.songs) {
      final sourceId = song.sourceId ?? 'local';
      previousBySource.putIfAbsent(sourceId, () => []).add(song);
    }

    final merged = <Song>[];
    for (final result in results) {
      if (result.shouldKeepPreviousSongs) {
        merged.addAll(previousBySource[result.sourceId] ?? const []);
      } else {
        merged.addAll(result.songs);
      }
    }

    // Sources that are disabled have no result, so their cached songs are
    // intentionally dropped from the active library.
    return _dedupe(merged)
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  String _statusMessage({
    required List<SourceScanResult> results,
    required int songCount,
    required int successCount,
    required int failedCount,
    required int skippedCount,
    required int needsConfigCount,
  }) {
    if (results.length == 1 && results.first.isSuccess) {
      return songCount == 0 ? '未找到音频文件' : '已扫描 $songCount 首歌曲';
    }
    if (successCount == 0) {
      if (failedCount > 0) return '所有音源扫描失败';
      if (needsConfigCount > 0) return '音源尚未配置';
      if (skippedCount > 0) return '已保留缓存，距上次扫描不足间隔';
    }
    if (failedCount == 0) {
      return '已扫描 $successCount 个音源，共 $songCount 首歌曲';
    }
    if (successCount == 0) return '所有音源扫描失败';
    return '已更新 $songCount 首歌曲，$failedCount 个音源失败';
  }

  Future<bool> _saveQuietly(List<Song> songs) async {
    try {
      await _storage.save(songs);
      return true;
    } catch (error, stackTrace) {
      // A successful scan should still be usable even if persistence fails.
      Log.error('保存音乐库失败: $error\n$stackTrace');
      return false;
    }
  }

  List<Song> _dedupe(List<Song> songs) {
    final seen = <String>{};
    return songs.where((song) => seen.add(song.uri)).toList();
  }
}
