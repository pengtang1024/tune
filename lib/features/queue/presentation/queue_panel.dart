import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/queue/presentation/queue_track_row.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/empty_state_view.dart';
import 'package:tune/shared/ui/source_label.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The play queue as a panel that floats over the page.
///
/// The panel only presents the queue. The order, the current track and the
/// operations all belong to [PlaybackController]; closing the panel changes
/// none of them. The host decides where the panel sits and how it enters.
class QueuePanel extends ConsumerWidget {
  /// Closes the panel. Every close action of the panel calls it, so the host
  /// that owns the open state decides what closing means.
  final VoidCallback onClose;

  const QueuePanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
    final settings = ref.watch(settingsControllerProvider);
    final sourceLabels = sourceLabelsOf(
      context.loc,
      ref.watch(
        musicSourcesControllerProvider.select(
          (value) => value.valueOrNull?.sources ?? const [],
        ),
      ),
    );

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CompactTokens.sidePanelRadius),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Header(
            count: queue.length,
            onClear: queue.isEmpty ? null : () => _confirmClear(context, ref),
            onClose: onClose,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          Expanded(
            child: queue.isEmpty
                ? EmptyStateView(
                    icon: Icons.queue_music_rounded,
                    title: context.loc.queueEmptyTitle,
                    subtitle: context.loc.queueEmptySubtitle,
                    action: FilledButton.icon(
                      onPressed: () {
                        onClose();
                        context.go('/library');
                      },
                      icon: const Icon(
                        Icons.library_music_outlined,
                        size: CompactTokens.icon16,
                      ),
                      label: Text(context.loc.queueGoToLibrary),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      CompactTokens.space8,
                      CompactTokens.space4,
                      CompactTokens.space8,
                      CompactTokens.space8,
                    ),
                    buildDefaultDragHandles: false,
                    itemCount: queue.length,
                    onReorderItem: (oldIndex, newIndex) {
                      // The list takes the moved track out before it names the
                      // place, so the number it hands over is the place in the
                      // list without it. The controller counts the place in the
                      // list with it, so the number goes back to that shape.
                      final drop = newIndex >= oldIndex
                          ? newIndex + 1
                          : newIndex;
                      controller.reorderQueue(oldIndex, drop);
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 2,
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(
                          CompactTokens.radius12,
                        ),
                        clipBehavior: Clip.antiAlias,
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
                        onDoubleTap: () => _toggleFavorite(ref, song),
                        waitsForDoubleClick: settings.onlyLikeOnDoubleClick,
                        onRemove: () => controller.removeFromQueue(index),
                        onToggleFavorite: () => _toggleFavorite(ref, song),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Marks the track, or takes the mark away when it is already there.
  void _toggleFavorite(WidgetRef ref, Song song) {
    ref.read(favoritesControllerProvider.notifier).toggle(song.uri);
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

/// Title, count, the action that empties the queue and the close action.
class _Header extends StatelessWidget {
  final int count;
  final VoidCallback? onClear;
  final VoidCallback onClose;

  const _Header({
    required this.count,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.space16,
        CompactTokens.space12,
        CompactTokens.space8,
        CompactTokens.space8,
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              context.loc.queueTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          Text(
            context.loc.libraryTrackCount(count),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
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
          const SizedBox(width: CompactTokens.space4),
          TuneTooltip(
            message: context.loc.close,
            child: IconButton(
              autofocus: true,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: CompactTokens.icon18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: CompactTokens.controlCompact,
                height: CompactTokens.controlCompact,
              ),
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
