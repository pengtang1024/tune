import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_animations.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class AppInteractions {
  AppInteractions._();

  static Widget clickableCard({
    required Widget child,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
    Color? splashColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius ?? AppDesignSystem.borderRadius8,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppDesignSystem.borderRadius8,
        splashColor: splashColor ?? AppDesignSystem.primary.withValues(alpha: 0.12),
        highlightColor: (splashColor ?? AppDesignSystem.primary).withValues(alpha: 0.06),
        child: child,
      ),
    );
  }

  static Widget clickableIcon({
    required IconData icon,
    VoidCallback? onTap,
    double? size,
    Color? color,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDesignSystem.spacing8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? AppDesignSystem.borderRadius8,
      ),
      child: Icon(icon, size: size ?? AppDesignSystem.iconSize24, color: color),
    ).wrapWithInteraction(onTap: onTap);
  }

  static Widget skeleton({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral300,
        borderRadius: borderRadius ?? AppDesignSystem.borderRadius4,
      ),
    );
  }

  static Widget skeletonText({
    double? width,
    double? lineHeight,
    int lines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: index == 0 ? EdgeInsets.zero : const EdgeInsets.only(top: 4),
          child: skeleton(
            width: width,
            height: lineHeight ?? 16,
            borderRadius: AppDesignSystem.borderRadius4,
          ),
        ),
      ),
    );
  }

  static Widget pressableScale({
    required Widget child,
    VoidCallback? onTap,
    double scaleValue = 0.97,
  }) {
    return _PressableScale(
      scaleValue: scaleValue,
      onTap: onTap,
      child: child,
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final double scaleValue;
  final VoidCallback? onTap;

  const _PressableScale({
    required this.child,
    required this.scaleValue,
    this.onTap,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween(begin: 1.0, end: widget.scaleValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

extension WidgetExtensions on Widget {
  Widget wrapWithInteraction({VoidCallback? onTap, BorderRadius? borderRadius}) {
    return AppInteractions.clickableCard(
      child: this,
      onTap: onTap,
      borderRadius: borderRadius,
    );
  }

  Widget withFadeIn({Duration? duration, Duration? delay}) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: duration ?? AppDesignSystem.duration400,
      child: this,
    );
  }

  Widget withSlideIn({
    Offset begin = const Offset(0.0, 0.3),
    Duration? duration,
    Duration? delay,
  }) {
    return AnimatedSlideTransition(
      child: this,
      begin: begin,
      duration: duration ?? AppDesignSystem.duration300,
      delay: delay,
    );
  }

  Widget withScaleIn({Duration? duration, Duration? delay}) {
    return ScaleFadeTransition(
      child: this,
      duration: duration ?? AppDesignSystem.duration400,
      delay: delay,
    );
  }

  Widget withPressableScale({VoidCallback? onTap, double scaleValue = 0.97}) {
    return AppInteractions.pressableScale(
      onTap: onTap,
      scaleValue: scaleValue,
      child: this,
    );
  }
}
