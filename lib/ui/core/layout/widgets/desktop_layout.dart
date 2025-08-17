import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/providers/router_providers.dart';
import 'package:tune/ui/core/layout/widgets/sidebar_menu.dart';
import 'package:tune/ui/core/layout/widgets/app_bar.dart';
import 'package:tune/ui/core/layout/providers/app_bar_providers.dart';
import 'package:tune/ui/core/layout/providers/layout_providers.dart';

class DesktopLayout extends ConsumerWidget {
  final Widget child;

  const DesktopLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前路由路径，用于确定菜单选中状态
    final currentRoute = GoRouterState.of(context).uri.toString();
    // 移除查询参数和锚点，只保留路径部分
    final cleanRoute = currentRoute.split('?')[0].split('#')[0];
    
    // 监听布局状态以响应侧边栏展开/收起变化
    final layoutState = ref.watch(layoutStateNotifierProvider);

    return Row(
      children: [
        // 左侧菜单区域（根据展开状态调整宽度）
        SidebarMenu(
          onMenuItemSelected: (item) {
            context.go(item.route);
            
            // 更新路由状态
            final routerNotifier = ref.read(routerProvider.notifier);
            routerNotifier.updateSelectedMenuItem(item.route);
          },
          currentRoute: cleanRoute,
        ),
        // 右侧区域（标题栏+内容区）
        Expanded(
          child: Column(
            children: [
              // 全局唯一的标题栏（固定高度）
              const CustomAppBar(),
              // 内容展示区（占右侧剩余空间）
              Expanded(
                child: child, // 仅在此区域进行页面切换更新
              ),
            ],
          ),
        ),
      ],
    );
  }
}