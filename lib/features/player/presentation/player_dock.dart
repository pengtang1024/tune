import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/features/player/presentation/audio_source_badge.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
import 'package:tune/shared/utils/duration_format.dart';
import 'package:tune/shared/ui/live_badge.dart';

class PlayerDock extends ConsumerWidget {
  /// Toggles the queue panel of the shell.
  ///
  /// The dock does not own the panel: the shell does. A null callback leaves
  /// the button disabled, which keeps a dock drawn on its own in tests and in
  /// previews from reaching for a panel that is not there.
  final VoidCallback? onToggleQueue;

  /// Whether the queue panel that the button toggles is open.
  final bool queueOpen;

  const PlayerDock({super.key, this.onToggleQueue, this.queueOpen = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final song = state.currentSong;
    final favorites = ref.watch(favoritesControllerProvider);

    return Container(
      // The bar keeps the height of the token, but it grows when the text
      // of the clock asks for more room. The desktop has a text scale of
      // its own, and a user who raises it gets a taller bar rather than a
      // clock that runs over the edge of it.
      constraints: const BoxConstraints(minHeight: CompactTokens.dockHeight),
      margin: const EdgeInsets.fromLTRB(
        CompactTokens.dockMargin,
        0,
        CompactTokens.dockMargin,
        CompactTokens.space12,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.dockPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(CompactTokens.dockRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          return Row(
            children: [
              // The two sides share the room evenly, so the transport in the
              // middle sits on the centre of the dock and not in the middle
              // of whatever the song title leaves free.
              Expanded(
                child: InkWell(
                  onTap: song == null
                      ? null
                      : () => context.push('/now-playing'),
                  borderRadius: BorderRadius.circular(CompactTokens.radius12),
                  child: Row(
                    children: [
                      ArtworkThumb(
                        path: song?.albumArtPath,
                        imageUrl: song?.artworkUrl,
                        size: CompactTokens.artworkDock,
                        radius: CompactTokens.radius12,
                      ),
                      const SizedBox(width: CompactTokens.space12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song?.title.isNotEmpty == true
                                  ? song!.title
                                  : context.loc.playerNoSongTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    song == null
                                        ? context.loc.playerDockReady
                                        : (song.artist.isEmpty
                                              ? context.loc.playerUnknownArtist
                                              : song.artist),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CompactTypography.mono(
                                      theme.colorScheme.onSurfaceVariant,
                                      size: CompactTypeScale.mark,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (state.audioSourceStatus !=
                                    AudioSourceStatus.local) ...[
                                  const SizedBox(width: 8),
                                  AudioSourceBadge(
                                    status: state.audioSourceStatus,
                                    progress: state.downloadProgress,
                                    dense: true,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: narrow
                    ? CompactTokens.dockTransportWidthNarrow
                    : CompactTokens.dockTransportWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ModeButton(
                          state: state,
                          onPressed: controller.cyclePlayMode,
                        ),
                        const SizedBox(width: CompactTokens.space8),
                        _DockIcon(
                          icon: Icons.skip_previous_rounded,
                          tooltip: context.loc.playerPrevious,
                          size: CompactTokens.icon20,
                          onPressed: state.hasTrack
                              ? controller.previous
                              : null,
                        ),
                        const SizedBox(width: CompactTokens.space4),
                        _PlayButton(
                          state: state,
                          onPressed: state.hasTrack && !state.isLoading
                              ? controller.togglePlayPause
                              : null,
                        ),
                        const SizedBox(width: CompactTokens.space4),
                        _DockIcon(
                          icon: Icons.skip_next_rounded,
                          tooltip: context.loc.playerNext,
                          size: CompactTokens.icon20,
                          onPressed: state.hasTrack ? controller.next : null,
                        ),
                        // The empty twin of the mode button keeps the play
                        // button on the centre of the dock: without it the
                        // group of buttons would lean to the left.
                        const SizedBox(
                          width:
                              CompactTokens.modeButtonSize +
                              CompactTokens.space8,
                        ),
                      ],
                    ),
                    const SizedBox(height: CompactTokens.space4),
                    Row(
                      children: [
                        _time(context, state.position),
                        Expanded(
                          child: state.currentSong?.isLiveStream ?? false
                              ? const LiveBadge()
                              : SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 4,
                                    ),
                                    overlayShape:
                                        SliderComponentShape.noOverlay,
                                  ),
                                  child: SizedBox(
                                    height: 18,
                                    child: Slider(
                                      value: _progress(state),
                                      onChanged: state.hasTrack
                                          ? (value) => controller.seekTo(
                                              Duration(
                                                milliseconds:
                                                    (state
                                                                .duration
                                                                .inMilliseconds *
                                                            value)
                                                        .round(),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                        ),
                        _time(context, state.duration),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!narrow) ...[
                      TuneTooltip(
                        message: state.volume > 0
                            ? context.loc.playerMute
                            : context.loc.playerUnmute,
                        child: IconButton(
                          onPressed: () =>
                              controller.setVolume(state.volume > 0 ? 0 : 1),
                          icon: Icon(
                            state.volume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            size: CompactTokens.icon18,
                          ),
                          color: theme.colorScheme.onSurfaceVariant,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      SizedBox(
                        width: 74,
                        child: Slider(
                          value: state.volume,
                          onChanged: controller.setVolume,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // The heart of the track that is playing. The card at the
                    // bottom of the window is the one surface that is always
                    // there, so the mark is one click away from wherever the
                    // reader is.
                    FavoriteButton(
                      isFavorite: song != null && favorites.contains(song.uri),
                      onPressed: song == null
                          ? null
                          : () => ref
                                .read(favoritesControllerProvider.notifier)
                                .toggle(song.uri),
                    ),
                    const SizedBox(width: CompactTokens.space4),
                    _DockIcon(
                      icon: Icons.queue_music_rounded,
                      tooltip: context.loc.queueTitle,
                      size: CompactTokens.icon20,
                      onPressed: onToggleQueue,
                      selected: queueOpen,
                    ),
                    _DockIcon(
                      icon: Icons.open_in_full_rounded,
                      tooltip: context.loc.playerExpandNowPlaying,
                      size: CompactTokens.icon18,
                      onPressed: song == null
                          ? null
                          : () => context.push('/now-playing'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _progress(PlaybackState state) {
    if (state.duration.inMilliseconds <= 0) return 0;
    return (state.position.inMilliseconds / state.duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  Widget _time(BuildContext context, Duration value) {
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

class _PlayButton extends StatelessWidget {
  final PlaybackState state;
  final VoidCallback? onPressed;
  const _PlayButton({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 34,
      height: 34,
      child: TuneTooltip(
        message: state.isPlaying
            ? context.loc.playerPause
            : context.loc.playerPlay,
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
          icon: state.isLoading
              ? CompactSpinner.small(color: theme.colorScheme.onPrimary)
              : Icon(
                  state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: CompactTokens.icon20,
                ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onPressed;
  final bool selected;
  const _DockIcon({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : onPressed == null
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
        : theme.colorScheme.onSurfaceVariant;

    return TuneTooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: size),
        color: color,
        style: selected
            ? IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CompactTokens.radius8),
                ),
              )
            : null,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final PlaybackState state;
  final VoidCallback onPressed;
  const _ModeButton({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state.playMode != PlayMode.sequential;
    final icon = switch (state.playMode) {
      PlayMode.sequential => Icons.repeat_rounded,
      PlayMode.repeatOne => Icons.repeat_one_rounded,
      PlayMode.shuffle => Icons.shuffle_rounded,
    };
    return TuneTooltip(
      message: switch (state.playMode) {
        PlayMode.sequential => context.loc.playerPlayModeSequential,
        PlayMode.repeatOne => context.loc.playerPlayModeRepeatOne,
        PlayMode.shuffle => context.loc.playerPlayModeShuffle,
      },
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: CompactTokens.modeButtonSize,
          height: CompactTokens.modeButtonSize,
          child: Icon(
            icon,
            size: CompactTokens.icon16,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
