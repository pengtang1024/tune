import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class AppAnimations {
  AppAnimations._();

  static PageRouteBuilder<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: AppDesignSystem.duration300,
    );
  }

  static PageRouteBuilder<T> slideInFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.05, 0.0);
        const end = Offset.zero;
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppDesignSystem.curveEaseOut,
        );
        final offsetAnimation = Tween(begin: begin, end: end).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      transitionDuration: AppDesignSystem.duration300,
    );
  }

  static PageRouteBuilder<T> scaleFadeIn<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final scaleTween = Tween(begin: 0.98, end: 1.0).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: scaleTween, child: child),
        );
      },
      transitionDuration: AppDesignSystem.duration300,
    );
  }

  static Widget staggeredList({
    required int itemCount,
    required Widget Function(BuildContext context, int index, Animation<double> animation) itemBuilder,
    Duration? duration,
    Duration? staggerDelay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? const Duration(milliseconds: 600),
      builder: (context, value, _) {
        return Column(
          children: List.generate(itemCount, (index) {
            final itemProgress = (value * itemCount - index).clamp(0.0, 1.0);
            return itemBuilder(context, index, AlwaysStoppedAnimation(itemProgress));
          }),
        );
      },
    );
  }

  static Widget springScale({
    required Widget child,
    required AnimationController controller,
    double begin = 0.95,
    double end = 1.0,
  }) {
    return ScaleTransition(
      scale: Tween(begin: begin, end: end).animate(
        CurvedAnimation(
          parent: controller,
          curve: const SpringCurve(),
        ),
      ),
      child: child,
    );
  }

  static Widget shimmerLoading({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return _ShimmerEffect(
      baseColor: baseColor ?? AppDesignSystem.neutral200,
      highlightColor: highlightColor ?? AppDesignSystem.neutral100,
      child: child,
    );
  }
}

class SpringCurve extends Curve {
  const SpringCurve();

  @override
  double transform(double t) {
    if (t <= 0.0 || t >= 1.0) return t;
    final value = pow(2, -10 * t) * sin((t - 0.075) * (2 * pi) / 0.3) + 1;
    return value.clamp(0.0, 1.0);
  }
}

class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerEffect({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _controller.value * 3, 0.0),
              end: Alignment(0.0 + _controller.value * 3, 0.0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class AnimatedSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset begin;
  final Duration? delay;
  final Curve? curve;
  final VoidCallback? onComplete;

  const AnimatedSlideTransition({
    super.key,
    required this.child,
    required this.duration,
    this.begin = const Offset(0.0, 0.3),
    this.delay,
    this.curve,
    this.onComplete,
  });

  @override
  State<AnimatedSlideTransition> createState() =>
      _AnimatedSlideTransitionState();
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
      curve: widget.curve ?? Curves.easeOutCubic,
    ));

    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (mounted) _controller.forward();
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

class ScaleFadeTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;

  const ScaleFadeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay,
  });

  @override
  State<ScaleFadeTransition> createState() => _ScaleFadeTransitionState();
}

class _ScaleFadeTransitionState extends State<ScaleFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (mounted) _controller.forward();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
