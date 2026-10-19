import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_song_row.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/search/presentation/online_search_sheet.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/empty_state_view.dart';

class LibraryPane extends ConsumerStatefulWidget {
  const LibraryPane({super.key});

  @override
  ConsumerState<LibraryPane> createState() => _LibraryPaneState();
}

class _LibraryPaneState extends ConsumerState<LibraryPane> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryControllerProvider);
    ref.listen<String?>(
      libraryControllerProvider.select((value) => value.valueOrNull?.query),
      (previous, next) {
        if (next == null || next == _searchController.text) return;
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
    );

    if (library.isLoading && !library.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = library.valueOrNull;
    if (state == null) {
      return EmptyStateView(
        icon: Icons.error_outline_rounded,
        title: '音乐库加载失败',
        subtitle: '${library.error ?? '未知错误'}',
        action: FilledButton(
          onPressed: () => ref.invalidate(libraryControllerProvider),
          child: const Text('重试'),
        ),
      );
    }

    final settings = ref.watch(settingsControllerProvider);
    final playback = ref.watch(
      playbackControllerProvider.select(
        (value) => (value.currentSong?.uri, value.isPlaying),
      ),
    );
    final sourceConfigs =
        ref.watch(musicSourcesControllerProvider).valueOrNull?.sources ??
        const [];
    final sourceNames = {
      for (final source in sourceConfigs) source.id: source.name,
    };
    final availableSources =
        state.songs
            .map((song) => song.sourceId ?? 'local')
            .toSet()
            .toList(growable: false)
          ..sort(
            (a, b) => (sourceNames[a] ?? a).compareTo(sourceNames[b] ?? b),
          );
    final currentUri = playback.$1;
    final isPlaying = playback.$2;
    final filteredSongs = state.filteredSongs;
    final hasSourceIssues = state.sourceSummaries.values.any(
      (summary) => summary.status != SourceScanStatus.success,
    );
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLLECTION',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        letterSpacing: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Library',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontFamily: 'Fraunces',
                        fontSize: 38,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '音乐库 · ${filteredSongs.length} 首',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CompactTokens.space12),
              OutlinedButton.icon(
                onPressed: () => showOnlineSearchSheet(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CompactTokens.space12,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 11),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                icon: const Icon(Icons.travel_explore_rounded, size: 16),
                label: const Text('在线搜索'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
          child: _Toolbar(
            controller: _searchController,
            state: state,
            filteredCount: filteredSongs.length,
            sources: availableSources,
            sourceNames: sourceNames,
            onQueryChanged: (value) {
              ref.read(libraryControllerProvider.notifier).setQuery(value);
            },
            onClearQuery: () {
              _searchController.clear();
              ref.read(libraryControllerProvider.notifier).setQuery('');
            },
            onSourceFilter: (value) {
              ref
                  .read(libraryControllerProvider.notifier)
                  .setSourceFilter(value);
            },
            onScan: state.isScanning || state.isLoading
                ? null
                : () => ref
                      .read(libraryControllerProvider.notifier)
                      .scan(settings.effectiveScanPaths),
          ),
        ),
        if (state.isScanning || state.errorMessage != null || hasSourceIssues)
          _ScanStatus(state: state),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(
                  context,
                  state,
                  filteredSongs,
                  currentUri,
                  isPlaying,
                  sourceNames,
                ),
        ),
        if (!state.hasSongs && !state.isScanning && state.errorMessage == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CompactTokens.space16,
              0,
              CompactTokens.space16,
              CompactTokens.space12,
            ),
            child: Text(
              '扫描目录：${settings.effectiveScanPaths.join('  ·  ')}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    LibraryState state,
    List<Song> songs,
    String? currentUri,
    bool isPlaying,
    Map<String, String> sourceNames,
  ) {
    if (songs.isEmpty) {
      if (state.query.trim().isNotEmpty && state.hasSongs) {
        return EmptyStateView(
          icon: Icons.search_off_rounded,
          title: '没有匹配的歌曲',
          subtitle: '换个关键词，或清除搜索条件',
          action: TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(libraryControllerProvider.notifier).setQuery('');
            },
            child: const Text('清除搜索'),
          ),
        );
      }

      if (state.sourceFilter != null && state.hasSongs) {
        return EmptyStateView(
          icon: Icons.filter_alt_off_rounded,
          title: '该来源暂无歌曲',
          subtitle: '切换到全部来源，或重新扫描该音源',
          action: TextButton(
            onPressed: () {
              ref
                  .read(libraryControllerProvider.notifier)
                  .setSourceFilter(null);
            },
            child: const Text('查看全部来源'),
          ),
        );
      }

      return EmptyStateView(
        icon: Icons.library_music_outlined,
        title: state.isScanning ? '正在扫描音乐' : '还没有音乐',
        subtitle: state.isScanning
            ? state.statusMessage
            : '扫描本地目录或已启用的在线音源，也可以在设置中调整音源。',
        action: state.isScanning
            ? null
            : FilledButton.icon(
                onPressed: () {
                  final settings = ref.read(settingsControllerProvider);
                  ref
                      .read(libraryControllerProvider.notifier)
                      .scan(settings.effectiveScanPaths);
                },
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('扫描全部音源'),
              ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: CompactTokens.space8),
      itemCount: songs.length,
      itemExtent: CompactTokens.rowHeight,
      itemBuilder: (context, index) {
        final song = songs[index];
        return LibrarySongRow(
          song: song,
          index: index,
          selected: song.uri == currentUri,
          playing: isPlaying,
          sourceName: song.sourceId == null || song.sourceId == 'local'
              ? null
              : sourceNames[song.sourceId] ?? song.sourceId,
          onTap: () {
            ref
                .read(playbackControllerProvider.notifier)
                .playQueue(songs, startIndex: index);
          },
          onAddToQueue: () {
            ref.read(playbackControllerProvider.notifier).addToQueue(song);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('已加入播放队列'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
          },
        );
      },
    );
  }
}

const _allSources = '__all_sources__';

class _Toolbar extends StatelessWidget {
  final TextEditingController controller;
  final LibraryState state;
  final int filteredCount;
  final List<String> sources;
  final Map<String, String> sourceNames;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String?> onSourceFilter;
  final VoidCallback? onScan;

  const _Toolbar({
    required this.controller,
    required this.state,
    required this.filteredCount,
    required this.sources,
    required this.sourceNames,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSourceFilter,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: CompactTokens.inputHeight,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                hintText: context.loc.search,
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: CompactTokens.icon16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                suffixIcon: state.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除搜索',
                        onPressed: onClearQuery,
                        icon: const Icon(Icons.close_rounded, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: CompactTokens.space8,
                  vertical: CompactTokens.space8,
                ),
                border: OutlineInputBorder(
                  borderRadius: CompactTokens.borderRadius8,
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: CompactTokens.borderRadius8,
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: CompactTokens.borderRadius8,
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ),
          if (sources.length > 1) ...[
            const SizedBox(width: CompactTokens.space4),
            SizedBox(
              width: CompactTokens.controlSmall,
              height: CompactTokens.controlSmall,
              child: PopupMenuButton<String>(
                tooltip: '筛选来源',
                padding: EdgeInsets.zero,
                initialValue: state.sourceFilter ?? _allSources,
                onSelected: (value) {
                  onSourceFilter(value == _allSources ? null : value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: _allSources,
                    height: 36,
                    child: Text('全部来源'),
                  ),
                  for (final sourceId in sources)
                    PopupMenuItem<String>(
                      value: sourceId,
                      height: 36,
                      child: Text(sourceNames[sourceId] ?? sourceId),
                    ),
                ],
                icon: Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: state.sourceFilter == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
          const SizedBox(width: CompactTokens.space8),
          Text(
            '$filteredCount 首',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: CompactTokens.space4),
          IconButton(
            tooltip: '扫描全部音源',
            onPressed: onScan,
            icon: state.isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(CompactTokens.controlSmall),
              minimumSize: const Size.square(CompactTokens.controlSmall),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanStatus extends StatelessWidget {
  final LibraryState state;

  const _ScanStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = state.errorMessage != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.space16,
        0,
        CompactTokens.space16,
        CompactTokens.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isScanning)
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: state.scanProgress,
                minHeight: 2,
                backgroundColor: theme.colorScheme.outlineVariant,
              ),
            ),
          const SizedBox(height: CompactTokens.space4),
          Text(
            isError ? state.errorMessage! : (state.statusMessage ?? ''),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
