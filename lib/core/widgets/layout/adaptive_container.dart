import 'package:flutter/material.dart';
import 'package:tune/core/config/platform_constants.dart';

/// 自适应容器组件
///
/// 根据平台调整内边距和其他布局属性
class AdaptiveContainer extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 外边距
  final EdgeInsets? margin;

  /// 内边距
  final EdgeInsets? padding;

  /// 装饰
  final Decoration? decoration;

  /// 约束
  final BoxConstraints? constraints;

  /// 构造函数
  const AdaptiveContainer({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.decoration,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets effectivePadding = padding ?? const EdgeInsets.all(16.0);
    EdgeInsets effectiveMargin = margin ?? EdgeInsets.zero;

    // 根据平台调整内边距
    if (PlatformConstants.isDesktop) {
      effectivePadding = padding ?? const EdgeInsets.all(24.0);
    } else if (PlatformConstants.isWeb) {
      effectivePadding = padding ?? const EdgeInsets.all(20.0);
    }

    return Container(
      margin: effectiveMargin,
      padding: effectivePadding,
      decoration: decoration,
      constraints: constraints,
      child: child,
    );
  }
}