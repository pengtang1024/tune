import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';
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
                      : () => _showNowPlaying(context, state),
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
                                  : '选择一首歌开始',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              song == null
                                  ? 'TUNE · READY'
                                  : (song.artist.isEmpty
                                        ? 'UNKNOWN ARTIST'
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
                          tooltip: '上一首',
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
                          tooltip: '下一首',
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
                                value: _progress(state),
                                onChanged: state.hasTrack
                                    ? (value) => controller.seekTo(
                                        Duration(
                                          milliseconds:
                                              (state.duration.inMilliseconds *
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
                        tooltip: state.volume > 0 ? '静音' : '恢复音量',
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
                      tooltip: '播放队列',
                      size: 19,
                      onPressed: () => context.go('/queue'),
                    ),
                    _DockIcon(
                      icon: Icons.open_in_full_rounded,
                      tooltip: '正在播放',
                      size: 17,
                      onPressed: song == null
                          ? null
                          : () => _showNowPlaying(context, state),
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

  void _showNowPlaying(BuildContext context, PlaybackState state) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Now playing',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          NowPlayingView(state: state),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
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
        tooltip: state.isPlaying ? '暂停' : '播放',
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
        PlayMode.sequential => '列表循环',
        PlayMode.repeatOne => '单曲循环',
        PlayMode.shuffle => '随机播放',
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

class NowPlayingView extends ConsumerWidget {
  final PlaybackState state;
  const NowPlayingView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(playbackControllerProvider.notifier);
    final current = ref.watch(playbackControllerProvider).currentSong;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 560,
          height: 460,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 50,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  ArtworkThumb(
                    path: current?.albumArtPath,
                    imageUrl: current?.artworkUrl,
                    size: 300,
                    radius: 22,
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'NOW PLAYING',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9,
                            letterSpacing: 1.8,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          current?.title ?? 'Tune',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontFamily: 'Fraunces',
                            fontSize: 38,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          current?.artist ?? 'Waiting for a track',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _DockIcon(
                              icon: Icons.skip_previous_rounded,
                              tooltip: '上一首',
                              size: 24,
                              onPressed: controller.previous,
                            ),
                            const SizedBox(width: 8),
                            _PlayButton(
                              state: state,
                              onPressed: controller.togglePlayPause,
                            ),
                            const SizedBox(width: 8),
                            _DockIcon(
                              icon: Icons.skip_next_rounded,
                              tooltip: '下一首',
                              size: 24,
                              onPressed: controller.next,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Slider(
                          value: state.duration.inMilliseconds <= 0
                              ? 0
                              : (state.position.inMilliseconds /
                                        state.duration.inMilliseconds)
                                    .clamp(0.0, 1.0),
                          onChanged: (value) => controller.seekTo(
                            Duration(
                              milliseconds:
                                  (state.duration.inMilliseconds * value)
                                      .round(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '关闭',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
