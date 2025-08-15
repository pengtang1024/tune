import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/providers/router_providers.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/ui/home/widgets/sidebar_menu.dart';
import 'package:tune/domain/models/menu_item.dart';

class DesktopHomeLayout extends ConsumerWidget {
  final Widget child;

  const DesktopHomeLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = ref.watch(routerProvider);
    final localizations = AppLocalizations.of(context);
    
    // 获取当前选中的菜单项
    MenuItem? selectedMenuItem;
    switch (routerState.selectedMenuItem) {
      case '/':
        selectedMenuItem = MenuItem(title: '', icon: Icons.home, route: '/');
        break;
      case '/recommend':
        selectedMenuItem = MenuItem(title: '', icon: Icons.recommend, route: '/recommend');
        break;
      case '/featured':
        selectedMenuItem = MenuItem(title: '', icon: Icons.star, route: '/featured');
        break;
      case '/library':
        selectedMenuItem = MenuItem(title: '', icon: Icons.library_music, route: '/library');
        break;
    }

    return Row(
      children: [
        // 使用SidebarMenu组件替换NavigationRail
        SidebarMenu(
          isExpanded: true,
          onExpandChanged: (bool expanded) {
            // 桌面端始终展开
          },
          onMenuItemSelected: (MenuItem item) {
            context.go(item.route);
            ref.read(routerProvider.notifier).updateSelectedMenuItem(item.route);
          },
          selectedMenuItem: selectedMenuItem,
        ),
        // 主内容区域
        Expanded(child: child),
      ],
    );
  }

  /// 导航到指定页面
  void _navigateTo(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        context.go('/');
        ref.read(routerProvider.notifier).updateSelectedMenuItem('/');
        break;
      case 1:
        context.go('/recommend');
        ref.read(routerProvider.notifier).updateSelectedMenuItem('/recommend');
        break;
      case 2:
        context.go('/featured');
        ref.read(routerProvider.notifier).updateSelectedMenuItem('/featured');
        break;
      case 3:
        context.go('/library');
        ref.read(routerProvider.notifier).updateSelectedMenuItem('/library');
        break;
    }
  }
}
