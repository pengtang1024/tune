import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/ui/core/layout/providers/sidebar_providers.dart';
import 'package:tune/core/extension/theme_extension.dart';

class SidebarMenu extends ConsumerWidget {
  final Function(MenuItem) onMenuItemSelected;
  final String currentRoute;

  const SidebarMenu({
    super.key,
    required this.onMenuItemSelected,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarState = ref.watch(sidebarMenuProvider);
    final isExpanded = sidebarState.isExpanded;

    final menuItems = [
      MenuItem(
        title: '主页',
        icon: Icons.home_outlined,
        route: '/',
      ),
      MenuItem(
        title: '推荐',
        icon: Icons.recommend_outlined,
        route: '/recommend',
      ),
      MenuItem(
        title: '精选',
        icon: Icons.star_outline,
        route: '/featured',
      ),
      MenuItem(
        title: '音乐库',
        icon: Icons.library_music_outlined,
        route: '/library',
      ),
    ];

    return Material(
      // 添加Material组件以支持ListTile
      child: Container(
        width: isExpanded ? 250 : 80,
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // 应用标题栏
            _buildAppHeader(context, isExpanded),
            // 菜单项目列表
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: menuItems.map((item) => _buildMenuItem(context, ref, item, currentRoute)).toList(),
              ),
            ),
            // 用户信息区域
            _buildUserSection(context, isExpanded),
            // 菜单展开/收缩按钮移到底部
            _buildExpandButton(context, ref, isExpanded),
          ],
        ),
      ),
    );
  }

  /// 构建应用头部组件
  ///
  /// @param context 上下文
  /// @param isExpanded 是否展开
  Widget _buildAppHeader(BuildContext context, bool isExpanded) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 应用图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.theme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.music_note,
              color: context.theme.colorScheme.onPrimary,
            ),
          ),
          // 应用名称 (仅在展开时显示)
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Text(
              'Tune',
              style: context.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.theme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建展开/收缩按钮
  ///
  /// @param context 上下文
  /// @param ref Provider引用
  /// @param isExpanded 是否展开
  Widget _buildExpandButton(BuildContext context, WidgetRef ref, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isExpanded ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => ref.read(sidebarMenuProvider.notifier).toggleExpanded(),
            icon: Icon(
              isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: isExpanded ? '收起菜单' : '展开菜单',
          ),
        ],
      ),
    );
  }

  /// 构建菜单项
  ///
  /// @param context 上下文
  /// @param ref Provider引用
  /// @param item 菜单项数据
  /// @param currentRoute 当前路由
  Widget _buildMenuItem(BuildContext context, WidgetRef ref, MenuItem item, String currentRoute) {
    final isExpanded = ref.watch(sidebarMenuProvider).isExpanded;
    // 修复路由匹配逻辑，确保正确识别当前选中项
    final isSelected = _isRouteSelected(currentRoute, item.route);

    // 桌面端：展开时图标和标题之间应有适当间距，收起时只显示图标，鼠标悬停或长按时显示提示信息
    if (isExpanded) {
      return ListTile(
        leading: Icon(
          item.icon,
          color: isSelected 
            ? context.theme.primaryColor
            : context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected 
              ? context.theme.primaryColor
              : context.theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onTap: () => onMenuItemSelected(item),
        horizontalTitleGap: 16.0, // 增加图标和标题之间的间距
      );
    } else {
      // 收起时只显示图标，使用InkWell和Tooltip显示提示信息
      return Tooltip(
        message: item.title,
        child: InkWell(
          onTap: () => onMenuItemSelected(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Icon(
              item.icon,
              color: isSelected 
                ? context.theme.primaryColor
                : context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
  }

  /// 判断路由是否被选中
  ///
  /// @param currentRoute 当前路由
  /// @param itemRoute 菜单项路由
  bool _isRouteSelected(String currentRoute, String itemRoute) {
    // 处理根路径的特殊情况
    if (itemRoute == '/') {
      return currentRoute == '/' || currentRoute.isEmpty;
    }
    
    // 对于其他路径，检查是否以该路径开头（处理带参数的路由）
    return currentRoute == itemRoute;
  }

  /// 构建用户信息区域
  ///
  /// @param context 上下文
  /// @param isExpanded 是否展开
  Widget _buildUserSection(BuildContext context, bool isExpanded) {
    // 使用Flexible包装用户信息区域，防止布局溢出
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 限制高度为最小必要尺寸
          children: [
            const Divider(),
            isExpanded
                ? ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.person,
                        color: context.theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      '用户名',
                      style: context.theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'user@example.com',
                      style: context.theme.textTheme.bodySmall?.copyWith(
                        color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    onTap: () {
                      // TODO: 导航到用户个人资料页面
                    },
                  )
                : InkWell(
                    onTap: () {
                      // TODO: 导航到用户个人资料页面
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.person,
                        color: context.theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}