import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/queue/presentation/queue_track_row.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/empty_state_view.dart';
import 'package:tune/shared/ui/page_heading.dart';
import 'package:tune/shared/ui/source_label.dart';

/// The play queue page.
///
/// The page owns the order of the queue; every entry is rendered by
/// [QueueTrackRow].
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
    final sourceNames = ref.watch(musicSourceNamesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 14),
          child: PageHeading(
            eyebrow: 'QUEUE',
            title: '播放队列',
            subtitle: '当前播放顺序',
            trailing: _QueueActions(
              count: queue.length,
              onClear: queue.isEmpty
                  ? null
                  : () => _confirmClear(context, ref),
            ),
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
                  padding: const EdgeInsets.fromLTRB(
                    28,
                    0,
                    28,
                    CompactTokens.space8,
                  ),
                  buildDefaultDragHandles: false,
                  itemCount: queue.length,
                  onReorder: controller.reorderQueue,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 2,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    return QueueTrackRow(
                      key: ValueKey(song.uri),
                      song: song,
                      index: index,
                      selected: index == currentIndex,
                      playing: isPlaying && song.uri == currentUri,
                      sourceName: sourceLabel(song, sourceNames),
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

/// Track count and the action that empties the queue.
class _QueueActions extends StatelessWidget {
  final int count;
  final VoidCallback? onClear;

  const _QueueActions({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count 首',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: CompactTokens.space8),
        TextButton(
          onPressed: onClear,
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
    );
  }
}
