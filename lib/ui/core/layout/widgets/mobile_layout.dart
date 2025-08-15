import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/providers/router_providers.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/extension/theme_extension.dart';

class MobileLayout extends ConsumerWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前路由路径，用于确定菜单选中状态
    final currentRoute = GoRouterState.of(context).uri.toString();
    // 移除查询参数和锚点，只保留路径部分
    final cleanRoute = currentRoute.split('?')[0].split('#')[0];

    // 获取路由状态提供者
    final routerState = ref.watch(routerProvider);

    return Scaffold(
      body: child,
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
            icon: Icon(Icons.music_note_outlined, color: context.theme.primaryColor.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.music_note, color: context.theme.primaryColor),
            label: '', // 移除label，使用tooltip替代
            tooltip: context.loc.recommend,
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline, color: context.theme.primaryColor.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.star, color: context.theme.primaryColor),
            label: '', // 移除label，使用tooltip替代
            tooltip: context.loc.featured,
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined, color: context.theme.primaryColor.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.library_music, color: context.theme.primaryColor),
            label: '', // 移除label，使用tooltip替代
            tooltip: context.loc.library,
          ),
        ],
      ),
    );
  }

  /// 根据菜单索引导航到对应页面
  void _navigateTo(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/recommend');
        break;
      case 2:
        context.go('/featured');
        break;
      case 3:
        // 导航到音乐库（音乐扫描页面也属于音乐库功能）
        context.go('/library');
        break;
    }

    // 更新路由状态
    final routerNotifier = ref.read(routerProvider.notifier);
    switch (index) {
      case 0:
        routerNotifier.updateSelectedMenuItem('/');
        break;
      case 1:
        routerNotifier.updateSelectedMenuItem('/recommend');
        break;
      case 2:
        routerNotifier.updateSelectedMenuItem('/featured');
        break;
      case 3:
        routerNotifier.updateSelectedMenuItem('/library');
        break;
    }
  }
}