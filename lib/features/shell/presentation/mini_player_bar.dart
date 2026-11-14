import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/application/playback_overview_provider.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The whole surface of the mini window.
///
/// The bar keeps the track, the three actions of the transport, the way back
/// to the normal form and, in the mini window, the line that shows how far
/// the track has come. It reads the slow half of the playback, so the clock
/// does not rebuild it, and it draws no page: the pages of the shell stay
/// mounted underneath while the window is small.
///
/// The mini window has no frame, so the bar is also the handle: a pointer
/// drag on it moves the window.
class MiniPlayerBar extends ConsumerWidget {
  /// Leaves the mini form and returns the window to the shell.
  final VoidCallback onRestore;

  /// Opens the queue. A phone passes it, because the dock that holds the
  /// queue button is replaced by this bar; the mini window has no room and
  /// leaves it null.
  final VoidCallback? onQueue;

  /// Starts moving the window. Only the mini window passes it: the bar is the
  /// only place left to grab once the frame is gone.
  final VoidCallback? onDrag;

  /// Draws the progress line along the bottom edge. Only the mini window
  /// passes true; on a phone the bar sits above the navigation bar, which
  /// already shows where the track is going.
  final bool showProgress;

  const MiniPlayerBar({
    super.key,
    required this.onRestore,
    this.onQueue,
    this.onDrag,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overview = ref.watch(playbackOverviewProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final song = overview.currentSong;
    final title = song == null || song.title.isEmpty
        ? context.loc.playerNoSongTitle
        : song.title;
    final artist = song == null
        ? context.loc.playerDockReady
        : (song.artist.isEmpty
              ? context.loc.playerUnknownArtist
              : song.artist);

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.space12,
        vertical: CompactTokens.space8,
      ),
      child: Row(
        children: [
          ArtworkThumb(
            path: song?.albumArtPath,
            imageUrl: song?.artworkUrl,
            size: CompactTokens.artworkDock,
            radius: CompactTokens.radius12,
          ),
          const SizedBox(width: CompactTokens.space10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CompactTypography.mono(
                    theme.colorScheme.onSurfaceVariant,
                    size: CompactTypeScale.mark,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: CompactTokens.space4),
          _MiniIcon(
            icon: Icons.skip_previous_rounded,
            tooltip: context.loc.playerPrevious,
            onPressed: overview.hasTrack ? controller.previous : null,
          ),
          _MiniPlayButton(
            status: overview.status,
            onPressed: overview.hasTrack && !overview.isLoading
                ? controller.togglePlayPause
                : null,
          ),
          _MiniIcon(
            icon: Icons.skip_next_rounded,
            tooltip: context.loc.playerNext,
            onPressed: overview.hasTrack ? controller.next : null,
          ),
          if (onQueue != null)
            _MiniIcon(
              key: const ValueKey('mini-queue'),
              icon: Icons.queue_music_rounded,
              tooltip: context.loc.queueTitle,
              onPressed: onQueue,
            ),
          _MiniIcon(
            key: const ValueKey('mini-expand'),
            icon: Icons.open_in_full_rounded,
            tooltip: context.loc.playerExpandNowPlaying,
            onPressed: onRestore,
          ),
        ],
      ),
    );

    Widget bar = Material(
      color: theme.colorScheme.surfaceContainer,
      child: showProgress
          ? Column(
              children: [
                Expanded(child: row),
                const _MiniProgress(),
              ],
            )
          : row,
    );

    final drag = onDrag;
    if (drag != null) {
      bar = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => drag(),
        child: bar,
      );
    }
    return bar;
  }
}

/// How far the track has come, drawn as a hairline along the bottom edge.
///
/// The position moves several times a second, so this strip is the only thing
/// that watches it: the title and the buttons above must not be rebuilt by
/// the clock.
class _MiniProgress extends ConsumerWidget {
  const _MiniProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clock = ref.watch(
      playbackControllerProvider.select(
        (state) => (state.position, state.duration),
      ),
    );
    return SizedBox(
      key: const ValueKey('mini-progress'),
      height: 2,
      width: double.infinity,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: _progressOf(clock.$1, clock.$2),
          child: ColoredBox(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}

double _progressOf(Duration position, Duration duration) {
  if (duration.inMilliseconds <= 0) return 0;
  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}

class _MiniPlayButton extends StatelessWidget {
  final PlaybackStatus status;
  final VoidCallback? onPressed;

  const _MiniPlayButton({required this.status, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = status == PlaybackStatus.playing;
    final isLoading = status == PlaybackStatus.loading;
    return SizedBox(
      width: 32,
      height: 32,
      child: TuneTooltip(
        message: isPlaying ? context.loc.playerPause : context.loc.playerPlay,
        child: IconButton.filled(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.primary.withValues(
              alpha: 0.3,
            ),
            shape: const CircleBorder(),
          ),
          icon: isLoading
              ? CompactSpinner.small(color: theme.colorScheme.onPrimary)
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: CompactTokens.icon18,
                ),
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _MiniIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onPressed == null
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
        : theme.colorScheme.onSurfaceVariant;
    return TuneTooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: CompactTokens.icon18),
        color: color,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      ),
    );
  }
}
