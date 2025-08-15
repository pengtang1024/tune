import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/providers/router_providers.dart';
import 'package:tune/ui/core/layout/widgets/sidebar_menu.dart';

class DesktopLayout extends ConsumerWidget {
  final Widget child;

  const DesktopLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前路由路径，用于确定菜单选中状态
    final currentRoute = GoRouterState.of(context).uri.toString();
    // 移除查询参数和锚点，只保留路径部分
    final cleanRoute = currentRoute.split('?')[0].split('#')[0];

    return Row(
      children: [
        // 使用SidebarMenu组件替换NavigationRail
        SidebarMenu(
          onMenuItemSelected: (item) {
            context.go(item.route);
            
            // 更新路由状态
            final routerNotifier = ref.read(routerProvider.notifier);
            routerNotifier.updateSelectedMenuItem(item.route);
          },
          currentRoute: cleanRoute,
        ),
        // 主内容区域
        Expanded(child: child),
      ],
    );
  }
}