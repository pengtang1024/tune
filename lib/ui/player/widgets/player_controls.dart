import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTrack = playerState.currentSong != null;

    return Semantics(
      label: '播放控制',
      child: Row(
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
                ? (playerState.isPlaying
                    ? () { HapticFeedback.mediumImpact(); playerNotifier.pause(); }
                    : () { HapticFeedback.mediumImpact(); playerNotifier.resume(); })
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
      ),
    );
  }

  IconData _getRepeatIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.shuffle: return Icons.shuffle_rounded;
      case PlayMode.repeatOne: return Icons.repeat_one_rounded;
      default: return Icons.repeat_rounded;
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDark;
  final bool _isLarge;

  const _ControlButton({required this.icon, required this.onTap, required this.isActive, required this.isDark}) : _isLarge = false;

  const _ControlButton.large({
    required this.icon,
    required this.onTap,
    required this.isDark,
  })  : isActive = false,
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
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppDesignSystem.primary.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(color: isActive ? AppDesignSystem.primary.withValues(alpha: 0.3) : Colors.transparent, width: 1.5),
          boxShadow: isActive ? [BoxShadow(color: AppDesignSystem.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Center(child: Icon(icon, color: isActive ? AppDesignSystem.primary : (isDark ? AppDesignSystem.neutral300 : AppDesignSystem.neutral600), size: iconSize)),
      ),
    );
  }
}

/// 播放/暂停按钮 — 带 scale + rotation 过渡动画
class _PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final bool hasTrack;
  final VoidCallback? onTap;

  const _PlayPauseButton({required this.isPlaying, required this.hasTrack, this.onTap});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant _PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isPlaying ? '暂停' : '播放',
      child: AppInteractions.pressableScale(
        scaleValue: 0.93,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.5, // 90度旋转
                child: child,
              ),
            );
          },
          child: AnimatedContainer(
            duration: AppDesignSystem.duration200,
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: widget.hasTrack
                  ? AppDesignSystem.primaryGradient
                  : LinearGradient(colors: [AppDesignSystem.neutral400, AppDesignSystem.neutral500]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppDesignSystem.primary.withValues(alpha: widget.isPlaying ? 0.4 : 0.2),
                  blurRadius: widget.isPlaying ? 28 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: AppDesignSystem.duration200,
                child: Icon(
                  widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(widget.isPlaying),
                  color: Colors.white,
                  size: AppDesignSystem.iconSize36,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
