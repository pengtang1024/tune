import 'package:flutter/material.dart';

/// 响应式布局组件
///
/// 适配不同屏幕尺寸的布局组件
class ResponsiveLayout extends StatelessWidget {
  /// 手机端布局
  final Widget mobile;

  /// 平板端布局
  final Widget? tablet;

  /// 桌面端布局
  final Widget? desktop;

  /// 断点宽度（平板）
  final double tabletBreakpoint;

  /// 断点宽度（桌面）
  final double desktopBreakpoint;

  /// 构造函数
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.tabletBreakpoint = 600,
    this.desktopBreakpoint = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= desktopBreakpoint && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= tabletBreakpoint && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}