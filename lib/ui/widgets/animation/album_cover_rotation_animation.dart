import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

/// 专辑封面旋转动画组件
/// 在音乐播放时显示旋转的专辑封面
class AlbumCoverRotationAnimation extends ThemedAnimationBase {
  final Widget? child;
  final Duration duration;
  final double size;

  const AlbumCoverRotationAnimation({
    super.key,
    this.child,
    this.duration = const Duration(seconds: 10),
    this.size = 60.0,
  });

  @override
  State<AlbumCoverRotationAnimation> createState() =>
      _AlbumCoverRotationAnimationState();
}

class _AlbumCoverRotationAnimationState
    extends ThemedAnimationStateBase<AlbumCoverRotationAnimation> {
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(widget.duration);
    repeatAnimation(); // 持续重复旋转

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi, // 360度
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear, // 线性旋转，保持匀速
    ));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: widget.child ??
                  Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.music_note,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: widget.size * 0.6,
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }
}