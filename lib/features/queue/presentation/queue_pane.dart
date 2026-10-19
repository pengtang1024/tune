import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/empty_state_view.dart';
import 'package:tune/shared/utils/duration_format.dart';

class QueuePane extends ConsumerWidget {
  const QueuePane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(
      playbackControllerProvider.select(
        (state) => (
          state.queue,
          state.currentIndex,
          state.currentSong?.uri,
          state.isPlaying,
        ),
      ),
    );
    final queue = view.$1;
    final currentIndex = view.$2;
    final currentUri = view.$3;
    final isPlaying = view.$4;
    final controller = ref.read(playbackControllerProvider.notifier);
    final sourceNames = ref.watch(
      musicSourcesControllerProvider.select((value) {
        final sources = value.valueOrNull?.sources ?? const [];
        return {for (final source in sources) source.id: source.name};
      }),
    );
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.space16,
            CompactTokens.space12,
            CompactTokens.space8,
            CompactTokens.space8,
          ),
          child: Row(
            children: [
              Text(
                '播放队列',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: CompactTokens.space8),
              Text(
                '${queue.length} 首',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: queue.isEmpty
                    ? null
                    : () => _confirmClear(context, ref),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CompactTokens.space8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                child: const Text('清空', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? EmptyStateView(
                  icon: Icons.queue_music_rounded,
                  title: '播放队列是空的',
                  subtitle: '从音乐库选择歌曲，或把歌曲加入队列',
                  action: FilledButton.icon(
                    onPressed: () => context.go('/library'),
                    icon: const Icon(Icons.library_music_outlined, size: 16),
                    label: const Text('去音乐库'),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: CompactTokens.space8),
                  buildDefaultDragHandles: false,
                  itemCount: queue.length,
                  onReorder: controller.reorderQueue,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 2,
                      color: theme.colorScheme.surfaceContainer,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    return _QueueSongRow(
                      key: ValueKey(song.uri),
                      song: song,
                      index: index,
                      selected: index == currentIndex,
                      playing: isPlaying && song.uri == currentUri,
                      sourceName:
                          song.sourceId == null || song.sourceId == 'local'
                          ? null
                          : sourceNames[song.sourceId] ?? song.sourceId,
                      onTap: () => controller.playAt(index),
                      onRemove: () => controller.removeFromQueue(index),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放队列？'),
        content: const Text('当前播放会停止，队列中的歌曲不会从音乐库删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(playbackControllerProvider.notifier).clearQueue();
    }
  }
}

class _QueueSongRow extends StatelessWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final String? sourceName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueSongRow({
    super.key,
    required this.song,
    required this.index,
    required this.selected,
    required this.playing,
    this.sourceName,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      child: Container(
        height: CompactTokens.rowHeight,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 2,
              height: double.infinity,
              color: selected ? theme.colorScheme.primary : Colors.transparent,
            ),
            const SizedBox(width: CompactTokens.space8),
            SizedBox(
              width: 22,
              child: Center(
                child: selected
                    ? Icon(
                        playing
                            ? Icons.equalizer_rounded
                            : Icons.play_arrow_rounded,
                        size: CompactTokens.icon16,
                        color: theme.colorScheme.primary,
                      )
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: muted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: CompactTokens.space8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title.isEmpty ? '未知歌曲' : song.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist.isEmpty ? '未知艺术家' : song.artist,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (sourceName != null) ...[
              const SizedBox(width: CompactTokens.space6),
              Tooltip(
                message: sourceName!,
                child: Icon(
                  Icons.public_rounded,
                  size: 12,
                  color: muted.withValues(alpha: 0.8),
                ),
              ),
            ],
            const SizedBox(width: CompactTokens.space8),
            Text(
              formatDuration(Duration(milliseconds: song.durationInMillis)),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: muted,
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: CompactTokens.icon16,
                    color: muted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                tooltip: context.loc.remove,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: muted,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(width: CompactTokens.space4),
          ],
        ),
      ),
    );
  }
}
