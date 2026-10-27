import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/providers/app_database_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/data/services/providers/song_download_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/data/impl/library_storage.dart';
import 'package:tune/features/library/data/library_storage.dart';
import 'package:tune/features/library/application/library_cache_limit_provider.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

final libraryStorageProvider = Provider<LibraryStorage>((ref) {
  final database = ref.watch(appDatabaseProvider.future);
  return createLibraryStorage(
    ref.watch(persistenceServiceProvider),
    database: () => database,
  );
});

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

  /// How many tracks one window of the library holds.
  ///
  /// A small library is read whole; a library larger than this is read a
  /// window at a time, so its size never decides the cost of the first frame.
  static const int windowSize = 1000;

  @override
  Future<LibraryState> build() async {
    _disposed = false;
    _autoScanStarted = false;
    _sourceService = ref.read(musicSourceServiceProvider);
    _storage = ref.read(libraryStorageProvider);
    ref.onDispose(() => _disposed = true);

    final total = await _storage.count();
    final songs = total > windowSize
        ? await _storage.page(offset: 0, limit: windowSize)
        : await _storage.load();
    final albums = await _storage.albumSummaries();
    return LibraryState(
      songs: List.unmodifiable(songs),
      total: total,
      hasMore: songs.length < total,
      albums: albums,
      statusMessage: songs.isEmpty
          ? null
          : AppStrings.instance.scanSongCountShort(songs.length),
    );
  }

  LibraryState get _current => state.valueOrNull ?? LibraryState.initial;

  /// Reads the next window of the library.
  ///
  /// The window is a slice of the same ordered table the first window came
  /// from, so the next window is appended as it is read — no second sort, no
  /// second copy of the tracks.
  Future<void> loadMore() async {
    if (_disposed || !state.hasValue || !_current.hasMore) return;

    final query = _current.query.trim();
    final sourceId = _current.sourceFilter;
    final next = query.isEmpty && sourceId == null
        ? await _storage.page(
            offset: _current.songs.length,
            limit: windowSize,
          )
        : await _storage.search(
            query: query,
            sourceId: sourceId,
            offset: _current.songs.length,
            limit: windowSize,
          );
    if (_disposed || !state.hasValue) return;

    if (next.isEmpty) {
      state = AsyncData(_current.copyWith(hasMore: false));
      return;
    }
    state = AsyncData(
      _current.copyWith(
        songs: List.unmodifiable([..._current.songs, ...next]),
        hasMore: next.length == windowSize,
      ),
    );
  }

  /// Marks the copies of the tracks in the library that are on this machine.
  ///
  /// A copy that was fetched before the app kept markers is marked now. The
  /// music library is then read with the markers in place, and the copy and
  /// the track it belongs to become one row.
  Future<void> _markCopies() async {
    final total = await _storage.count();
    if (total == 0) return;

    // A copy may be anywhere in the library, not only in the first window:
    // the rows are marked a batch at a time so a large library is still
    // covered without holding all of it in memory.
    const batch = 500;
    for (var offset = 0; offset < total; offset += batch) {
      if (_disposed) return;
      final songs = offset == 0 && total <= windowSize
          ? state.valueOrNull?.songs ?? const <Song>[]
          : await _storage.page(offset: offset, limit: batch);
      if (songs.isEmpty) break;
      try {
        await ref.read(songDownloadServiceProvider).markCopiesOf(songs);
      } catch (error, stackTrace) {
        // A copy that cannot be marked stays a track of its own; the library
        // still works.
        Log.error('标记已下载的副本失败: $error\n$stackTrace');
      }
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

    // A scan is a whole-library operation: the list it refreshes is the
    // library, not the result of the last search.
    state = AsyncData(
      _current.copyWith(
        query: '',
        sourceFilter: null,
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

      final summaries = <String, SourceScanSummary>{
        for (final result in results)
          result.sourceId: SourceScanSummary.fromResult(result),
      };

      // The scanned tracks travel to the database a window at a time; the
      // controller never holds more than one window of the library. A source
      // that failed or was skipped wrote nothing, so the rows it brought
      // before are kept without any merging here.
      var written = 0;
      var saved = true;
      for (final result in results) {
        if (!result.isSuccess) continue;
        try {
          written += await _storage.ingest(result.songs);
        } catch (error, stackTrace) {
          // A scan whose rows cannot be written keeps the library it had and
          // does not mark the source as scanned, so the next scan retries.
          Log.error('保存音乐库失败: $error\n$stackTrace');
          saved = false;
        }
        if (_disposed || generation != _scanGeneration) return;
      }
      var deactivated = 0;
      if (saved) {
        // The rows the scan does not cover are the sources that are off now
        // and the files that are gone from the folders the scan reads.
        deactivated = await _deactivateUncovered(
          enabled: enabled,
          results: results,
          localPaths: scanPaths,
        );
        if (_disposed || generation != _scanGeneration) return;
        await _prune();
        if (_disposed || generation != _scanGeneration) return;
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

      final total = await _storage.count();
      if (_disposed || generation != _scanGeneration) return;
      // A scan that changed nothing keeps the window it had: the list is the
      // input of the whole viewport, and a new list — even an equal one —
      // rebuilds every visible row.
      final songs = written > 0 || deactivated > 0
          ? List<Song>.unmodifiable(await _window(query: '', sourceId: null))
          : _current.songs;
      state = AsyncData(
        _current.copyWith(
          songs: songs,
          total: total,
          hasMore: songs.length < total,
          albums: saved ? await _storage.albumSummaries() : null,
          scanStatus: LibraryScanStatus.completed,
          scanProgress: 1,
          isLoading: false,
          statusMessage: _statusMessage(
            results: results,
            songCount: total,
            successCount: successCount,
            failedCount: failedCount,
            skippedCount: skippedCount,
            needsConfigCount: needsConfigCount,
          ),
          errorMessage: successCount == 0 && failedCount > 0 && total == 0
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
  /// The files the desktop hands to the player belong in the library, and so
  /// do the tracks the reader picks from an online search. The batch is
  /// merged into the database a window at a time, and the page reads its
  /// window from the library again — the batch itself is never held whole.
  Future<bool> addSongs(List<Song> songs) async {
    if (songs.isEmpty) return false;
    await future;
    if (_disposed || !state.hasValue) return false;

    var written = 0;
    try {
      written = await _storage.ingest(songs);
    } catch (error, stackTrace) {
      // A batch that cannot be written leaves the library as it was.
      Log.error('保存音乐库失败: $error\n$stackTrace');
    }
    if (_disposed || !state.hasValue) return false;

    final filterActive = _current.query.isNotEmpty || _current.sourceFilter != null;
    if (written > 0 || filterActive) {
      await _reloadForFilter();
      return written > 0;
    }
    final total = await _storage.count();
    if (_disposed || !state.hasValue) return false;
    state = AsyncData(_current.copyWith(total: total));
    return false;
  }

  /// Notes that a track played, so the prune keeps it over an untouched one.
  /// The tracks of one album, read on demand.
  Future<List<Song>> albumSongs(String key) => _storage.albumSongs(key);

  Future<void> notePlayed(String uri) async {
    if (uri.isEmpty) return;
    await future;
    if (_disposed) return;
    await _storage.markPlayed(uri);
  }

  Future<void> setQuery(String query) async {
    if (_disposed || !state.hasValue) return;
    state = AsyncData(_current.copyWith(query: query));
    await _reloadForFilter();
  }

  /// Removes a source's songs immediately, e.g. after the reader removes it.
  Future<void> dropSource(String sourceId) async {
    if (_disposed || !state.hasValue) return;

    final summaries = Map<String, SourceScanSummary>.of(
      _current.sourceSummaries,
    )..remove(sourceId);

    state = AsyncData(
      _current.copyWith(
        sourceSummaries: Map.unmodifiable(summaries),
        sourceFilter: _current.sourceFilter == sourceId
            ? null
            : _current.sourceFilter,
      ),
    );
    await _storage.removeSource(sourceId);
    if (_disposed || !state.hasValue) return;
    await _reloadForFilter();
  }

  Future<void> setSourceFilter(String? sourceId) async {
    if (_disposed || !state.hasValue) return;
    final normalized = sourceId?.trim();
    state = AsyncData(
      _current.copyWith(
        sourceFilter: normalized == null || normalized.isEmpty
            ? null
            : normalized,
      ),
    );
    await _reloadForFilter();
  }

  /// Reads the window that matches the current query and source filter.
  Future<void> _reloadForFilter() async {
    if (_disposed || !state.hasValue) return;
    final query = _current.query.trim();
    final sourceId = _current.sourceFilter;

    if (query.isEmpty && sourceId == null) {
      final total = await _storage.count();
      final songs = total > windowSize
          ? await _storage.page(offset: 0, limit: windowSize)
          : await _storage.load();
      final albums = await _storage.albumSummaries();
      if (_disposed || !state.hasValue) return;
      state = AsyncData(
        _current.copyWith(
          songs: List.unmodifiable(songs),
          total: total,
          hasMore: songs.length < total,
          albums: albums,
        ),
      );
      return;
    }

    final total = await _storage.countMatching(
      query: query,
      sourceId: sourceId,
    );
    final songs = await _storage.search(
      query: query,
      sourceId: sourceId,
      offset: 0,
      limit: windowSize,
    );
    final albums = await _storage.albumSummaries();
    if (_disposed || !state.hasValue) return;
    state = AsyncData(
      _current.copyWith(
        songs: List.unmodifiable(songs),
        total: total,
        hasMore: songs.length < total,
        albums: albums,
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

  /// Marks the rows the scan does not cover as outside the library.
  ///
  /// Marks the rows the scan does not cover as outside the library.
  ///
  /// The sources that are off now, and the local files that no longer sit
  /// under one of the folders the scan reads, are not part of the library
  /// any more. A local scan that failed (the drive is away) keeps every
  /// local row — only a scan that reads its folders answers for them.
  Future<int> _deactivateUncovered({
    required List<MusicSourceConfig> enabled,
    required List<SourceScanResult> results,
    required List<String> localPaths,
  }) {
    final enabledIds = {for (final source in enabled) source.id};
    final localSources = enabled.where((source) => source.isLocal);
    final localSucceeded = results.any(
      (result) =>
          result.isSuccess &&
          localSources.any((source) => source.id == result.sourceId),
    );
    return _storage.deactivateUncovered(
      enabledSourceIds: enabledIds,
      localPaths: localSucceeded ? localPaths : const [],
    );
  }

  /// The window the page shows: what matches the query and the source filter,
  /// read from the database.
  ///
  /// A small library is read whole; a larger one is read a window at a time,
  /// so its size never decides the cost of the frame.
  Future<List<Song>> _window({
    required String query,
    required String? sourceId,
  }) async {
    if (query.isEmpty && sourceId == null) {
      final total = await _storage.count();
      return total > windowSize
          ? _storage.page(offset: 0, limit: windowSize)
          : _storage.load();
    }
    return _storage.search(
      query: query,
      sourceId: sourceId,
      offset: 0,
      limit: windowSize,
    );
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

  /// Drops what the storage ranks lowest, and answers what it removed.
  Future<void> _prune() async {
    final limit = ref.read(libraryCacheLimitProvider);
    if (limit <= 0) return;
    // The window does not hold every marked track, so the pins are written
    // to the whole table before a prune decides what to drop.
    await _storage.syncPinned(_pinnedUris());
    await _storage.prune(limit);
  }

  /// The tracks a prune must never drop.
  ///
  /// A favorite stays. The queue is not read here: it lives in the player,
  /// and the library must not pull the player up to merge a scan.
  Set<String> _pinnedUris() => ref.read(favoritesControllerProvider).ids;
}
