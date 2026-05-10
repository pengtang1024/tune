import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? surfaceColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isElevated;
  final bool isBordered;
  final bool isGradient;
  final Gradient? gradient;
  final bool isGlass;
  final double glassBlur;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.surfaceColor,
    this.boxShadow,
    this.borderRadius,
    this.borderSide,
    this.onTap,
    this.onLongPress,
    this.isElevated = true,
    this.isBordered = false,
    this.isGradient = false,
    this.gradient,
    this.isGlass = false,
    this.glassBlur = 10.0,
  });

  factory ModernCard.simple({
    Key? key,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    required Widget child,
  }) {
    return ModernCard(
      key: key,
      padding: padding,
      onTap: onTap,
      isElevated: false,
      child: child,
    );
  }

  factory ModernCard.elevated({
    Key? key,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    required Widget child,
  }) {
    return ModernCard(
      key: key,
      padding: padding,
      onTap: onTap,
      isElevated: true,
      child: child,
    );
  }

  factory ModernCard.bordered({
    Key? key,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
    VoidCallback? onTap,
    required Widget child,
  }) {
    return ModernCard(
      key: key,
      padding: padding,
      onTap: onTap,
      isBordered: true,
      borderSide: borderColor != null ? BorderSide(color: borderColor) : null,
      child: child,
    );
  }

  factory ModernCard.gradient({
    Key? key,
    EdgeInsetsGeometry? padding,
    Gradient? gradient,
    VoidCallback? onTap,
    required Widget child,
  }) {
    return ModernCard(
      key: key,
      padding: padding,
      onTap: onTap,
      isGradient: true,
      gradient: gradient,
      child: child,
    );
  }

  factory ModernCard.glass({
    Key? key,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    double blurAmount = 10.0,
    required Widget child,
  }) {
    return ModernCard(
      key: key,
      padding: padding,
      onTap: onTap,
      isGlass: true,
      glassBlur: blurAmount,
      isElevated: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGlass) return _buildGlassCard(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardSurfaceColor = surfaceColor ??
        (isDark ? AppDesignSystem.neutral800 : Colors.white);

    final cardBoxShadow = boxShadow ??
        (isElevated ? AppDesignSystem.shadowMedium : []);

    final cardBorderRadius = borderRadius ?? AppDesignSystem.borderRadius12;

    Widget cardChild = child;
    if (padding != null) {
      cardChild = Padding(padding: padding!, child: cardChild);
    }

    Widget cardContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isGradient ? null : cardSurfaceColor),
        gradient: isGradient
            ? (gradient ?? AppDesignSystem.primaryGradient)
            : null,
        borderRadius: cardBorderRadius,
        boxShadow: cardBoxShadow,
        border: isBordered || borderSide != null
            ? (borderSide != null
                ? Border.fromBorderSide(borderSide!)
                : Border.all(
                    color: isDark
                        ? AppDesignSystem.neutral700
                        : AppDesignSystem.neutral200,
                    width: 1,
                  ))
            : null,
      ),
      child: cardChild,
    );

    if (onTap != null && onLongPress == null) {
      return Container(
        margin: margin,
        child: AppInteractions.pressableScale(
          scaleValue: 0.98,
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    if (onTap != null || onLongPress != null) {
      return Container(
        margin: margin,
        child: AppInteractions.clickableCard(
          onTap: onTap,
          borderRadius: cardBorderRadius,
          child: cardContent,
        ),
      );
    }

    return Container(margin: margin, child: cardContent);
  }

  Widget _buildGlassCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorderRadius = borderRadius ?? AppDesignSystem.borderRadius16;

    Widget cardChild = child;
    if (padding != null) {
      cardChild = Padding(padding: padding!, child: cardChild);
    }

    Widget cardContent = ClipRRect(
      borderRadius: cardBorderRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: cardBorderRadius,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
            ),
            child: cardChild,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: AppInteractions.pressableScale(
          scaleValue: 0.98,
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return Container(margin: margin, child: cardContent);
  }
}
