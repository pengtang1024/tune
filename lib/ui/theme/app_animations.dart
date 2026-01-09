import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 统一的动画和过渡效果系统
/// 提供应用中所有动画效果的定义和工具方法
class AppAnimations {
  AppAnimations._();

  // ========== 页面过渡动画 ==========
  
  /// 淡入淡出过渡
  static PageRouteBuilder<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: AppDesignSystem.duration300,
    );
  }

  /// 滑入过渡（从右到左）
  static PageRouteBuilder<T> slideInFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = AppDesignSystem.curveEaseInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: AppDesignSystem.duration300,
    );
  }

  // ========== 组件动画 ==========
  
  /// 淡入动画组件
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    Duration? delay,
    Curve? curve,
    VoidCallback? onComplete,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: duration ?? AppDesignSystem.duration400,
      onEnd: onComplete,
      child: child,
    );
  }

  /// 交互动画
  static Widget rippleEffect({
    required Widget child,
    VoidCallback? onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius ?? AppDesignSystem.borderRadius8,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppDesignSystem.borderRadius8,
        splashColor: rippleColor ?? AppDesignSystem.primary.withOpacity(0.2),
        highlightColor: (rippleColor ?? AppDesignSystem.primary).withOpacity(0.1),
        child: child,
      ),
    );
  }

  /// 滑入动画
  static Widget slideIn({
    required Widget child,
    Offset begin = const Offset(0.0, 0.3),
    Duration? duration,
    Duration? delay,
    Curve? curve,
  }) {
    return AnimatedSlideTransition(
      child: child,
      duration: duration ?? AppDesignSystem.duration300,
    );
  }

  /// 列表项动画
  static Widget animatedListItem({
    required Widget child,
    int index = 0,
    Duration? duration,
  }) {
    return AnimatedSlideTransition(
      child: child,
      duration: duration ?? AppDesignSystem.duration300,
    );
  }
}

/// 简化的滑动过渡动画
class AnimatedSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedSlideTransition({
    required this.child,
    required this.duration,
    this.onComplete,
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
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
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