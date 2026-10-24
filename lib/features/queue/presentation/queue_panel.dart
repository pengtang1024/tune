import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/application/playback_overview_provider.dart';
import 'package:tune/features/queue/presentation/queue_track_row.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/empty_state_view.dart';
import 'package:tune/shared/ui/live_badge.dart';
import 'package:tune/shared/ui/source_label.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
import 'package:tune/shared/utils/duration_format.dart';

/// The play queue as a panel that floats over the page.
///
/// The panel only presents the queue. The order, the current track and the
/// operations all belong to [PlaybackController]; closing the panel changes
/// none of them. The host decides where the panel sits and how it enters.
class QueuePanel extends ConsumerStatefulWidget {
  /// Closes the panel. Every close action of the panel calls it, so the host
  /// that owns the open state decides what closing means.
  final VoidCallback onClose;

  /// Whether the panel carries the compact transport.
  ///
  /// The shell already has the player dock outside the panel, so it leaves
  /// this off. The now playing page has no dock and the panel can cover its
  /// transport, so it turns this on.
  final bool showTransport;

  const QueuePanel({
    super.key,
    required this.onClose,
    this.showTransport = false,
  });

  @override
  ConsumerState<QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends ConsumerState<QueuePanel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Open the list where the music is, not at the top of a queue that may
    // hold a hundred tracks. The row height is the base height; a larger text
    // scale only makes the estimate a little short, never wrong.
    final state = ref.read(playbackControllerProvider);
    final index = state.currentIndex;
    final offset = index > 0 && index < state.queue.length
        ? index * CompactTokens.listRowHeight
        : 0.0;
    _scrollController = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The cursor is taken by its address, not by its place in the queue:
    // looking a track up in the queue costs a walk through it, and this
    // selector runs on every tick of the clock.
    final view = ref.watch(
      playbackControllerProvider.select(
        (state) => (state.queue, state.currentUri, state.isPlaying),
      ),
    );
    final queue = view.$1;
    final currentUri = view.$2;
    final isPlaying = view.$3;
    final currentIndex = currentUri == null
        ? -1
        : queue.indexWhere((song) => song.uri == currentUri);
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
            onClear: queue.isEmpty ? null : () => _confirmClear(context),
            onClose: widget.onClose,
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
                        widget.onClose();
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
                    scrollController: _scrollController,
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
                        onDoubleTap: () => _markFavorite(song),
                        waitsForDoubleClick:
                            settings.onlyLikeOnDoubleClick,
                        onRemove: () => controller.removeFromQueue(index),
                        onToggleFavorite: () => _toggleFavorite(song),
                        dense: true,
                      );
                    },
                  ),
          ),
          if (widget.showTransport) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            const _MiniTransport(),
          ],
        ],
      ),
    );
  }

  /// Marks the track, or takes the mark away when it is already there.
  void _toggleFavorite(Song song) {
    ref.read(favoritesControllerProvider.notifier).toggle(song.uri);
  }

  /// A double click adds a mark; it never takes one away.
  void _markFavorite(Song song) {
    ref.read(favoritesControllerProvider.notifier).mark(song.uri);
  }

  Future<void> _confirmClear(BuildContext context) async {
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

/// A compact transport for the case where the host has no player dock.
class _MiniTransport extends ConsumerWidget {
  const _MiniTransport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(playbackOverviewProvider);
    final clock = ref.watch(
      playbackControllerProvider.select(
        (state) => (state.position, state.duration),
      ),
    );
    final controller = ref.read(playbackControllerProvider.notifier);
    final theme = Theme.of(context);
    final hasTrack = overview.hasTrack;
    final isPlaying = overview.isPlaying;
    final isLoading = overview.isLoading;
    final position = clock.$1;
    final duration = clock.$2;
    final isLive = overview.currentSong?.isLiveStream ?? false;
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.space12,
        CompactTokens.space6,
        CompactTokens.space12,
        CompactTokens.space10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive)
            const Align(alignment: Alignment.centerLeft, child: LiveBadge())
          else
            Row(
              children: [
                _MiniTime(value: position),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: SizedBox(
                      height: 18,
                      child: Slider(
                        value: progress,
                        onChanged: hasTrack
                            ? (value) => controller.seekTo(
                                Duration(
                                  milliseconds:
                                      (duration.inMilliseconds * value).round(),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                _MiniTime(value: duration),
              ],
            ),
          const SizedBox(height: CompactTokens.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniButton(
                icon: Icons.skip_previous_rounded,
                tooltip: context.loc.playerPrevious,
                onPressed: hasTrack ? controller.previous : null,
              ),
              const SizedBox(width: CompactTokens.space10),
              SizedBox(
                width: 34,
                height: 34,
                child: TuneTooltip(
                  message: isPlaying
                      ? context.loc.playerPause
                      : context.loc.playerPlay,
                  child: IconButton.filled(
                    onPressed: hasTrack && !isLoading
                        ? controller.togglePlayPause
                        : null,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      disabledBackgroundColor: theme.colorScheme.primary
                          .withValues(alpha: 0.3),
                      shape: const CircleBorder(),
                    ),
                    icon: isLoading
                        ? CompactSpinner.small(
                            color: theme.colorScheme.onPrimary,
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: CompactTokens.icon18,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: CompactTokens.space10),
              _MiniButton(
                icon: Icons.skip_next_rounded,
                tooltip: context.loc.playerNext,
                onPressed: hasTrack ? controller.next : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TuneTooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: CompactTokens.icon18),
        color: onPressed == null
            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
            : theme.colorScheme.onSurfaceVariant,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _MiniTime extends StatelessWidget {
  final Duration value;

  const _MiniTime({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Text(
        formatDuration(value),
        textAlign: TextAlign.center,
        style: CompactTypography.mono(
          Theme.of(context).colorScheme.onSurfaceVariant,
          size: CompactTypeScale.mark,
        ),
      ),
    );
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
          Expanded(
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
              ],
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
