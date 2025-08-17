import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/widgets/desktop_layout.dart';
import 'package:tune/ui/core/layout/widgets/mobile_layout.dart';
import 'package:tune/utils/device_utils.dart';

/// 响应式外壳：根据设备类型显示不同菜单
class ResponsiveShell extends ConsumerWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 判断设备类型（宽度≥600为桌面端）
    final isDesktop = DeviceUtils.isDesktop(context);
    return Scaffold(
      body: isDesktop
          ? DesktopLayout(child: child) // 桌面端侧边栏
          : MobileLayout(child: child), // 移动端底部导航
    );
  }
}

/// 桌面端布局：侧边栏菜单
