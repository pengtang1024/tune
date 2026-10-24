import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/core/utils/text_order.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/data/services/providers/song_download_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/data/impl/library_storage.dart';
import 'package:tune/features/library/data/library_storage.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

final libraryStorageProvider = Provider<LibraryStorage>(
  (ref) => createLibraryStorage(ref.watch(persistenceServiceProvider)),
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
      statusMessage: songs.isEmpty
          ? null
          : AppStrings.instance.scanSongCountShort(songs.length),
    );
  }

  LibraryState get _current => state.valueOrNull ?? LibraryState.initial;

  /// Marks the copies of the tracks in the library that are on this machine.
  ///
  /// A copy that was fetched before the app kept markers is marked now. The
  /// music library is then read with the markers in place, and the copy and
  /// the track it belongs to become one row.
  Future<void> _markCopies() async {
    final songs = state.valueOrNull?.songs ?? const <Song>[];
    if (songs.isEmpty) return;

    try {
      await ref.read(songDownloadServiceProvider).markCopiesOf(songs);
    } catch (error, stackTrace) {
      // A copy that cannot be marked stays a track of its own; the library
      // still works.
      Log.error('标记已下载的副本失败: $error\n$stackTrace');
    }
  }

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
        statusMessage: AppStrings.instance.scanPreparing,
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
            errorMessage: AppStrings.instance.scanNoEnabledSources,
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
            errorMessage: AppStrings.instance.scanNoLocalFolders,
          ),
        );
        return;
      }

      final progressBySource = <String, double>{
        for (final source in enabled) source.id: 0,
      };
      var lastPercent = -1;

      // Copies that were fetched before the app kept markers are marked
      // before the music library is read, so the scan knows the file is a
      // copy of a track and not a track of its own.
      await _markCopies();

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
            statusMessage: AppStrings.instance.scanProgressPercent(percent),
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
      await ref
          .read(musicSourcesControllerProvider.notifier)
          .recordScanResults(results);
      if (_disposed || generation != _scanGeneration) return;

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
          errorMessage: successCount == 0 && failedCount > 0 && songs.isEmpty
              ? AppStrings.instance.scanAllSourcesFailed
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
          errorMessage: AppStrings.instance.scanFailed('$error'),
        ),
      );
    }
  }

  /// Puts songs into the library.
  ///
  /// The files the desktop hands to the player belong in the library, so they
  /// show up in the list like every other track.
  Future<void> addSongs(List<Song> songs) async {
    if (songs.isEmpty) return;
    await future;
    if (_disposed || !state.hasValue) return;

    final merged = _dedupe([..._current.songs, ...songs]);
    state = AsyncData(
      _current.copyWith(songs: List<Song>.unmodifiable(merged)),
    );
    await _saveQuietly(merged);
  }

  void setQuery(String query) {
    if (_disposed || !state.hasValue) return;
    state = AsyncData(_current.copyWith(query: query));
  }

  /// Removes a source's songs immediately, e.g. after the reader removes it.
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
        _current.copyWith(
          isLoading: false,
          errorMessage: AppStrings.instance.clearLibraryFailed('$error'),
        ),
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
    return _dedupe(merged)..sort((a, b) => compareText(a.title, b.title));
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
      return songCount == 0
          ? AppStrings.instance.scanNoAudioFiles
          : AppStrings.instance.scanSongCount(songCount);
    }
    if (successCount == 0) {
      // A source that was skipped or that failed keeps the songs of the last
      // scan, so the library still holds them. The scan did not fill the
      // library again, but it did not empty it either.
      if (songCount > 0) return AppStrings.instance.scanCachedTooSoon;
      if (failedCount > 0) return AppStrings.instance.scanAllSourcesFailed;
      if (needsConfigCount > 0) {
        return AppStrings.instance.scanSourceNotConfigured;
      }
      if (skippedCount > 0) return AppStrings.instance.scanCachedTooSoon;
    }
    if (failedCount == 0) {
      // The generated getters order their parameters alphabetically:
      // scanSummary(songs, sources).
      return AppStrings.instance.scanSummary(songCount, successCount);
    }
    if (successCount == 0) return AppStrings.instance.scanAllSourcesFailed;
    // The generated getters order their parameters alphabetically:
    // scanUpdated(failed, songs).
    return AppStrings.instance.scanUpdated(failedCount, songCount);
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
    final merged = <String, Song>{};
    for (final song in songs) {
      final known = merged[song.uri];
      // A track that is on the disk and a track that comes from a source are
      // one track: the copy keeps the identity of the source, so the two
      // entries meet and become one row that knows both.
      merged[song.uri] = known == null ? song : known.mergeWith(song);
    }
    return merged.values.toList();
  }
}
