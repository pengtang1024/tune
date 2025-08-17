import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/providers/layout_providers.dart';
import 'package:tune/ui/core/layout/widgets/desktop_layout.dart';
import 'package:tune/ui/core/layout/widgets/mobile_layout.dart';
import 'package:tune/utils/device_utils.dart';

class ScreenLayout extends ConsumerWidget {
  final Widget child;

  const ScreenLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听布局状态
    ref.watch(layoutStateNotifierProvider);

    // 根据设备类型选择合适的布局
    if (DeviceUtils.isDesktop(context)) {
      return DesktopLayout(child: child);
    } else {
      return MobileLayout(child: child);
    }
  }
}

class ScreenContentLayout extends ConsumerWidget {
  final Widget child;

  const ScreenContentLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}

class RouterContent extends StatelessWidget {
  const RouterContent({super.key});

  @override
  Widget build(BuildContext context) {
    // 移除占位符，允许路由系统处理内容
    return const SizedBox.shrink();
  }
}