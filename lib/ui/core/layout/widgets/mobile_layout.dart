import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/router_providers.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/extension/theme_extension.dart';
import 'package:tune/ui/core/layout/widgets/app_bar.dart';
import 'package:tune/ui/core/layout/providers/app_bar_providers.dart';

class MobileLayout extends ConsumerWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取路由状态提供者
    final routerState = ref.watch(routerProvider);

    return Scaffold(
      appBar: const CustomAppBar(), // 全局唯一的标题栏
      body: child, // 内容展示区
      bottomNavigationBar: NavigationBar(
        selectedIndex: routerState.getSelectedIndex(),
        onDestinationSelected: (int index) {
          _navigateTo(context, ref, index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: context.theme.primaryColor.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.home, color: context.theme.primaryColor),
            label: '', // 移除label，使用tooltip替代
            tooltip: context.loc.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: context.theme.primaryColor.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.explore, color: context.theme.primaryColor),
            label: '',
            tooltip: '发现', // TODO: 使用本地化
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined, color: context.theme.primaryColor.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.library_music, color: context.theme.primaryColor),
            label: '',
            tooltip: context.loc.library,
          ),
        ],
      ),
    );
  }

  /// 导航到指定索引的页面
  void _navigateTo(BuildContext context, WidgetRef ref, int index) {
    final router = ref.read(routerProvider.notifier);
    router.goToIndex(index);
  }
}