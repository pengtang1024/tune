import 'package:flutter/material.dart';
import 'themed_animation_base.dart';

/// 播放状态动画组件
/// 根据播放器状态显示不同的动画效果
class PlayingStateAnimation extends ThemedAnimationBase {
  final bool isPlaying;
  final Duration duration;

  const PlayingStateAnimation({
    super.key,
    this.isPlaying = true,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<PlayingStateAnimation> createState() => _PlayingStateAnimationState();
}

class _PlayingStateAnimationState
    extends ThemedAnimationStateBase<PlayingStateAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(widget.duration);
    
    if (widget.isPlaying) {
      repeatAnimation();
    }

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant PlayingStateAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 当播放状态改变时，更新动画状态
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        repeatAnimation();
      } else {
        resetAnimation();
      }
    }
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            Icons.play_arrow,
            color: theme.colorScheme.primary,
          ),
        );
      },
    );
  }
}