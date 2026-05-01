import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化卡片组件
/// 提供一致的卡片样式和交互效果
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
  });

  /// 创建一个简单的卡片
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
      child: child,
    );
  }

  /// 创建一个突出的卡片
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

  /// 创建一个带边框的卡片
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

  /// 创建一个渐变卡片
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color cardSurfaceColor = surfaceColor ?? 
        (isDark ? AppDesignSystem.neutral800 : Colors.white);

    List<BoxShadow> cardBoxShadow = boxShadow ?? 
        (isElevated ? AppDesignSystem.shadowMedium : []);

    BorderRadius cardBorderRadius = borderRadius ?? AppDesignSystem.borderRadius12;

    Widget cardChild = child;

    // 添加内边距
    if (padding != null) {
      cardChild = Padding(padding: padding!, child: cardChild);
    }

    // 创建卡片内容
    Widget cardContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isGradient ? null : cardSurfaceColor,
        gradient: isGradient ? (gradient ?? AppDesignSystem.primaryGradient) : null,
        borderRadius: cardBorderRadius,
        boxShadow: cardBoxShadow,
        border: isBordered
            ? (borderSide != null 
                ? Border.fromBorderSide(borderSide!) 
                : Border.all(
                    color: isDark ? AppDesignSystem.neutral700 : AppDesignSystem.neutral200,
                    width: 1,
                  )
              )
            : null,
      ),
      child: cardChild,
    );

    // 如果有点击事件，包装为 InkWell
    if (onTap != null || onLongPress != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: cardBorderRadius,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: cardBorderRadius,
            splashColor: AppDesignSystem.primary.withValues(alpha: 0.1),
            highlightColor: AppDesignSystem.primary.withValues(alpha: 0.05),
            child: cardContent,
          ),
        ),
      );
    }

    // 否则只添加外边距
    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

/// 玻璃态卡片组件
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blurAmount;
  final double opacity;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blurAmount = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardChild = child;
    if (padding != null) {
      cardChild = Padding(padding: padding!, child: cardChild);
    }

    Widget cardContent = ClipRRect(
      borderRadius: borderRadius ?? AppDesignSystem.borderRadius16,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: opacity)
              : Colors.black.withValues(alpha: opacity),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: cardChild,
        ),
      ),
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? AppDesignSystem.borderRadius16,
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}