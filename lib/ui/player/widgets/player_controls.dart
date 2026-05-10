import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasTrack = playerState.currentSong != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.shuffle_rounded,
          onTap: hasTrack ? playerNotifier.togglePlayMode : null,
          isActive: playerState.playMode == PlayMode.shuffle,
          isDark: isDark,
        ),
        const SizedBox(width: AppDesignSystem.spacing16),
        _ControlButton.large(
          icon: Icons.skip_previous_rounded,
          onTap: hasTrack ? playerNotifier.previous : null,
          isDark: isDark,
        ),
        const SizedBox(width: AppDesignSystem.spacing20),
        _PlayPauseButton(
          isPlaying: playerState.isPlaying,
          hasTrack: hasTrack,
          onTap: hasTrack
              ? (playerState.isPlaying ? playerNotifier.pause : playerNotifier.resume)
              : null,
        ),
        const SizedBox(width: AppDesignSystem.spacing20),
        _ControlButton.large(
          icon: Icons.skip_next_rounded,
          onTap: hasTrack ? playerNotifier.next : null,
          isDark: isDark,
        ),
        const SizedBox(width: AppDesignSystem.spacing16),
        _ControlButton(
          icon: _getRepeatIcon(playerState.playMode),
          onTap: hasTrack ? () {} : null,
          isActive: playerState.playMode != PlayMode.sequential,
          isDark: isDark,
        ),
      ],
    );
  }

  IconData _getRepeatIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.shuffle:
        return Icons.shuffle_rounded;
      case PlayMode.repeatOne:
        return Icons.repeat_one_rounded;
      default:
        return Icons.repeat_rounded;
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDark;
  final bool _isLarge;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.isActive,
    required this.isDark,
  }) : _isLarge = false;

  const _ControlButton.large({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  })  : icon = icon,
        onTap = onTap,
        isActive = false,
        isDark = isDark,
        _isLarge = true;

  @override
  Widget build(BuildContext context) {
    final size = _isLarge ? 52.0 : 44.0;
    final iconSize = _isLarge ? AppDesignSystem.iconSize28 : AppDesignSystem.iconSize24;

    return AppInteractions.pressableScale(
      scaleValue: 0.92,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDesignSystem.duration200,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppDesignSystem.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? AppDesignSystem.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppDesignSystem.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive
                ? AppDesignSystem.primary
                : (isDark ? AppDesignSystem.neutral300 : AppDesignSystem.neutral600),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool hasTrack;
  final VoidCallback? onTap;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.hasTrack,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppInteractions.pressableScale(
      scaleValue: 0.93,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDesignSystem.duration200,
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: hasTrack
              ? AppDesignSystem.primaryGradient
              : LinearGradient(
                  colors: [
                    AppDesignSystem.neutral400,
                    AppDesignSystem.neutral500,
                  ],
                ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppDesignSystem.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: AppDesignSystem.duration200,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(isPlaying),
              color: Colors.white,
              size: AppDesignSystem.iconSize36,
            ),
          ),
        ),
      ),
    );
  }
}
