import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/features/player/presentation/audio_source_badge.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/utils/duration_format.dart';

class PlayerDock extends ConsumerWidget {
  const PlayerDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final song = state.currentSong;

    return Container(
      height: 88,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
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
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: song == null
                      ? null
                      : () => context.push('/now-playing'),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      ArtworkThumb(
                        path: song?.albumArtPath,
                        imageUrl: song?.artworkUrl,
                        size: 54,
                        radius: 12,
                      ),
                      const SizedBox(width: 12),
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13.5,
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
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                      color: theme.colorScheme.onSurfaceVariant,
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
                width: narrow ? 220 : 300,
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
                        const SizedBox(width: 8),
                        _DockIcon(
                          icon: Icons.skip_previous_rounded,
                          tooltip: context.loc.playerPrevious,
                          size: 20,
                          onPressed: state.hasTrack
                              ? controller.previous
                              : null,
                        ),
                        const SizedBox(width: 4),
                        _PlayButton(
                          state: state,
                          onPressed: state.hasTrack && !state.isLoading
                              ? controller.togglePlayPause
                              : null,
                        ),
                        const SizedBox(width: 4),
                        _DockIcon(
                          icon: Icons.skip_next_rounded,
                          tooltip: context.loc.playerNext,
                          size: 20,
                          onPressed: state.hasTrack ? controller.next : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _time(context, state.position),
                        Expanded(
                          child: state.currentSong?.isLiveStream ?? false
                              ? const _LiveMark()
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
                flex: narrow ? 1 : 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!narrow) ...[
                      IconButton(
                        tooltip: state.volume > 0
                            ? context.loc.playerMute
                            : context.loc.playerUnmute,
                        onPressed: () =>
                            controller.setVolume(state.volume > 0 ? 0 : 1),
                        icon: Icon(
                          state.volume == 0
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          size: 17,
                        ),
                        color: theme.colorScheme.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
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
                    _DockIcon(
                      icon: Icons.queue_music_rounded,
                      tooltip: context.loc.queueTitle,
                      size: 19,
                      onPressed: () => context.go('/queue'),
                    ),
                    _DockIcon(
                      icon: Icons.open_in_full_rounded,
                      tooltip: context.loc.playerNowPlaying,
                      size: 17,
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
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The mark that replaces the seek bar of a live stream.
class _LiveMark extends StatelessWidget {
  const _LiveMark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          context.loc.playerLiveBadge,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 8,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
            color: color,
          ),
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
      child: IconButton.filled(
        tooltip: state.isPlaying
            ? context.loc.playerPause
            : context.loc.playerPlay,
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
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 20,
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
  const _DockIcon({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
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
    return Tooltip(
      message: switch (state.playMode) {
        PlayMode.sequential => context.loc.playerPlayModeSequential,
        PlayMode.repeatOne => context.loc.playerPlayModeRepeatOne,
        PlayMode.shuffle => context.loc.playerPlayModeShuffle,
      },
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(
            icon,
            size: 16,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
