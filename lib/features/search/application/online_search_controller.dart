import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/search/domain/online_search_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/utils/logger.dart';

final onlineSearchControllerProvider =
    AutoDisposeAsyncNotifierProvider<OnlineSearchController, OnlineSearchState>(
      OnlineSearchController.new,
    );

/// Owns transient online search results. It never mutates the library cache.
class OnlineSearchController
    extends AutoDisposeAsyncNotifier<OnlineSearchState> {
  int _generation = 0;
  bool _disposed = false;

  @override
  Future<OnlineSearchState> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const OnlineSearchState();
  }

  Future<void> search(String rawQuery) async {
    final query = rawQuery.trim();
    final generation = ++_generation;
    if (query.isEmpty) {
      state = const AsyncData(OnlineSearchState());
      return;
    }

    final sources =
        ref.read(musicSourcesControllerProvider).valueOrNull?.sources ??
        const <MusicSourceConfig>[];
    final remoteSources = sources
        .where((source) => source.enabled && !source.isLocal)
        .toList(growable: false);
    if (remoteSources.isEmpty) {
      state = AsyncData(
        OnlineSearchState(
          query: query,
          message: AppStrings.instance.searchNoSourcesEnabled,
        ),
      );
      return;
    }

    state = AsyncData(
      OnlineSearchState(
        query: query,
        isSearching: true,
        progress: {for (final source in remoteSources) source.id: 0},
      ),
    );

    try {
      final results = await ref
          .read(musicSourceServiceProvider)
          .search(
            sources: remoteSources,
            query: query,
            onProgress: (sourceId, progress) {
              if (_disposed || generation != _generation) return;
              final current = state.valueOrNull;
              if (current == null || !current.isSearching) return;
              state = AsyncData(
                current.copyWith(
                  progress: {...current.progress, sourceId: progress},
                ),
              );
            },
          );
      if (_disposed || generation != _generation) return;

      final bySource = {for (final result in results) result.sourceId: result};
      final total = results.fold<int>(
        0,
        (sum, result) => sum + result.songs.length,
      );
      state = AsyncData(
        OnlineSearchState(
          query: query,
          results: bySource,
          cursors: {
            for (final result in results)
              if (result.cursor != null) result.sourceId: result.cursor!,
          },
          message: total == 0 ? AppStrings.instance.searchNoMatch : null,
        ),
      );
    } catch (error, stackTrace) {
      Log.error('在线搜索失败: $error\n$stackTrace');
      if (_disposed || generation != _generation) return;
      state = AsyncData(
        OnlineSearchState(
          query: query,
          message: AppStrings.instance.searchFailed('$error'),
        ),
      );
    }
  }

  /// Fetches the next window of one source and appends it to the results.
  ///
  /// A source without pages answers with the window it already gave, so the
  /// button reports that there is nothing more instead of repeating it.
  Future<void> loadMore(String sourceId) async {
    final current = state.valueOrNull;
    if (current == null || current.isSearching || current.loadingMore != null) {
      return;
    }
    final result = current.results[sourceId];
    if (result == null || result.songs.isEmpty) return;

    final sources =
        ref.read(musicSourcesControllerProvider).valueOrNull?.sources ??
        const <MusicSourceConfig>[];
    MusicSourceConfig? source;
    for (final candidate in sources) {
      if (candidate.id == sourceId) {
        source = candidate;
        break;
      }
    }
    if (source == null) return;

    final service = ref.read(musicSourceServiceProvider);
    final adapter = service.adapterFor(source.sourceType);
    if (adapter == null || !adapter.supportsPaging) {
      state = AsyncData(
        current.copyWith(message: AppStrings.instance.searchNoMore),
      );
      return;
    }

    final generation = _generation;
    state = AsyncData(current.copyWith(loadingMore: sourceId));
    try {
      final cursor = current.cursors[sourceId];
      final results = await service.search(
        sources: [source],
        query: current.query,
        offsets: cursor == null ? {sourceId: result.songs.length} : const {},
        cursors: cursor == null ? const {} : {sourceId: cursor},
      );
      if (_disposed || generation != _generation) return;

      final fresh = results.single;
      final merged = _append(result, fresh);
      state = AsyncData(
        current.copyWith(
          results: {...current.results, sourceId: merged},
          cursors: {
            for (final entry in current.cursors.entries)
              if (entry.key != sourceId) entry.key: entry.value,
            if (merged.cursor != null) sourceId: merged.cursor!,
          },
          loadingMore: null,
          message: merged.songs.length == result.songs.length
              ? AppStrings.instance.searchNoMore
              : null,
        ),
      );
    } catch (error, stackTrace) {
      Log.error('加载更多失败: $error\n$stackTrace');
      if (_disposed || generation != _generation) return;
      state = AsyncData(
        current.copyWith(
          loadingMore: null,
          message: AppStrings.instance.searchFailed('$error'),
        ),
      );
    }
  }

  /// Appends the new window to the tracks already shown.
  SourceScanResult _append(SourceScanResult current, SourceScanResult fresh) {
    final seen = {for (final song in current.songs) song.uri};
    final songs = [
      ...current.songs,
      for (final song in fresh.songs)
        if (seen.add(song.uri)) song,
    ];
    return SourceScanResult(
      sourceId: current.sourceId,
      status: fresh.isSuccess ? current.status : fresh.status,
      songs: songs,
      message: songs.length == current.songs.length
          ? AppStrings.instance.searchNoMore
          : null,
      cursor: fresh.cursor,
    );
  }

  void clear() {
    _generation++;
    state = const AsyncData(OnlineSearchState());
  }
}
