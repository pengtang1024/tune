import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 简化的动画系统（临时版本）
class AppAnimations {
  AppAnimations._();

  /// 淡入动画组件
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    VoidCallback? onComplete,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: duration ?? AppDesignSystem.duration400,
      onEnd: onComplete,
      child: child,
    );
  }

  /// 滑入动画组件
  static Widget slideIn({
    Offset begin = const Offset(0.0, 0.3),
    Duration? duration,
    VoidCallback? onComplete,
    required Widget child,
  }) {
    return AnimatedSlideTransition(
      begin: begin,
      duration: duration ?? AppDesignSystem.duration400,
      onComplete: onComplete,
      child: child,
    );
  }
}

/// 简化的滑动过渡动画
class AnimatedSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback? onComplete;
  final Offset begin;
  final Duration? delay;
  final Curve? curve;

  const AnimatedSlideTransition({
    this.onComplete,
    required this.duration,
    this.begin = const Offset(0.0, 0.3),
    this.delay,
    this.curve,
    super.key,
    required this.child,
  });

  @override
  State<AnimatedSlideTransition> createState() => _AnimatedSlideTransitionState();
}

class _AnimatedSlideTransitionState extends State<AnimatedSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _offsetAnimation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? Curves.easeOut,
    ));

    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}