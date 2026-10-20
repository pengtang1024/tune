import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/player/application/list_double_click.dart';
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
    final favorites = ref.watch(favoritesControllerProvider);
    final sourceLabels = sourceLabelsOf(
      context.loc,
      ref.watch(
        musicSourcesControllerProvider.select(
          (value) => value.valueOrNull?.sources ?? const [],
        ),
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            CompactTokens.pageTopPadding,
            CompactTokens.pageGutter,
            CompactTokens.pageHeadingGap,
          ),
          child: PageHeading(
            // The queue belongs to the collection, so it names the same
            // section as the library instead of repeating its own title.
            eyebrow: context.loc.libraryEyebrow,
            title: context.loc.queueTitle,
            subtitle: context.loc.queueSubtitle,
            trailing: _QueueActions(
              count: queue.length,
              onClear: queue.isEmpty ? null : () => _confirmClear(context, ref),
            ),
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? EmptyStateView(
                  icon: Icons.queue_music_rounded,
                  title: context.loc.queueEmptyTitle,
                  subtitle: context.loc.queueEmptySubtitle,
                  action: FilledButton.icon(
                    onPressed: () => context.go('/library'),
                    icon: const Icon(
                      Icons.library_music_outlined,
                      size: CompactTokens.icon16,
                    ),
                    label: Text(context.loc.queueGoToLibrary),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    CompactTokens.pageGutter,
                    0,
                    CompactTokens.pageGutter,
                    CompactTokens.space8,
                  ),
                  buildDefaultDragHandles: false,
                  itemCount: queue.length,
                  onReorderItem: (oldIndex, newIndex) {
                    // The list takes the moved track out before it names the
                    // place, so the number it hands over is the place in the
                    // list without it. The controller counts the place in the
                    // list with it, so the number goes back to that shape.
                    final drop = newIndex >= oldIndex ? newIndex + 1 : newIndex;
                    controller.reorderQueue(oldIndex, drop);
                  },
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
                      isFavorite: favorites.contains(song.uri),
                      source: sourceLabel(song, sourceLabels),
                      onTap: () => controller.playAt(index),
                      onDoubleTap: () => ref
                          .read(listDoubleClickProvider)
                          .like(song),
                      onRemove: () => controller.removeFromQueue(index),
                      onToggleFavorite: () => ref
                          .read(favoritesControllerProvider.notifier)
                          .toggle(song.uri),
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
        title: Text(context.loc.queueClearTitle),
        content: Text(context.loc.queueClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.clear),
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
          context.loc.libraryTrackCount(count),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: CompactTokens.space8),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, CompactTokens.controlTiny),
            padding: const EdgeInsets.symmetric(
              horizontal: CompactTokens.space8,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          child: Text(context.loc.clear, style: theme.textTheme.labelMedium),
        ),
      ],
    );
  }
}
