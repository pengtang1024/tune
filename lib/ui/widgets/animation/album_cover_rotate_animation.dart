import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 专辑封面旋转动画组件
/// 显示专辑封面旋转效果
class AlbumCoverRotateAnimation extends ThemedAnimationBase {
  final double size;
  final Widget? coverWidget;

  const AlbumCoverRotateAnimation({
    super.key,
    this.size = 200.0,
    this.coverWidget,
  });

  @override
  State<AlbumCoverRotateAnimation> createState() =>
      _AlbumCoverRotateAnimationState();
}

class _AlbumCoverRotateAnimationState
    extends ThemedAnimationStateBase<AlbumCoverRotateAnimation> {
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 5000));
    repeatAnimation();

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value * 2 * 3.14159, // 旋转角度
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child:
                  widget.coverWidget ??
                  Container(
                    color: theme.colorScheme.primary,
                    child: Center(
                      child: Icon(
                        Icons.album,
                        size: widget.size * 0.6,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }
}
