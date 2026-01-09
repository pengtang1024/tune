import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_animations.dart';

/// 统一的交互效果系统
/// 提供应用中所有交互效果的定义和工具方法
class AppInteractions {
  AppInteractions._();

  // ========== 手势检测 ==========
  
  /// 创建可点击的卡片效果
  static Widget clickableCard({
    required Widget child,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
    Color? splashColor,
    bool enableScale = true,
    double scaleValue = 0.98,
  }) {
    return AppAnimations.rippleEffect(
      onTap: onTap,
      borderRadius: borderRadius,
      rippleColor: splashColor,
      child: child,
    );
  }

  /// 创建可点击的图标按钮
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
      child: Icon(
        icon,
        size: size ?? AppDesignSystem.iconSize24,
        color: color,
      ),
    ).wrapWithInteraction(
      onTap: onTap,
      borderRadius: borderRadius ?? AppDesignSystem.borderRadius8,
    );
  }

  // ========== 加载效果 ==========
  
  /// 创建骨架屏效果
  static Widget skeleton({
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor ?? AppDesignSystem.neutral300,
        borderRadius: borderRadius ?? AppDesignSystem.borderRadius4,
      ),
    );
  }

  /// 创建骨架屏文本效果
  static Widget skeletonText({
    double? width,
    double? lineHeight,
    int lines = 1,
    EdgeInsetsGeometry? padding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: index == 0 ? EdgeInsets.zero : const EdgeInsets.only(top: 4.0),
          child: skeleton(
            width: width,
            height: lineHeight ?? 16.0,
            borderRadius: AppDesignSystem.borderRadius4,
          ),
        ),
      ),
    );
  }
}

/// 扩展方法
extension WidgetExtensions on Widget {
  /// 包装交互效果
  Widget wrapWithInteraction({
    VoidCallback? onTap,
    BorderRadius? borderRadius,
    Color? splashColor,
    bool enableScale = true,
  }) {
    return AppInteractions.clickableCard(
      child: this,
      onTap: onTap,
      borderRadius: borderRadius,
      splashColor: splashColor,
      enableScale: enableScale,
    );
  }

  /// 添加淡入动画
  Widget withFadeIn({
    Duration? duration,
    Duration? delay,
  }) {
    return AppAnimations.fadeIn(
      child: this,
      duration: duration,
      delay: delay,
    );
  }

  /// 添加滑入动画
  Widget withSlideIn({
    Offset begin = const Offset(0.0, 0.3),
    Duration? duration,
    Duration? delay,
  }) {
    return AppAnimations.slideIn(
      child: this,
      begin: begin,
      duration: duration,
      delay: delay,
    );
  }
}