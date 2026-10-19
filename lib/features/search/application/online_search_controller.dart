import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
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

  void clear() {
    _generation++;
    state = const AsyncData(OnlineSearchState());
  }
}
