import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/ui/core/layout/providers/layout_providers.dart';
import 'package:tune/core/extension/theme_extension.dart';
import 'package:tune/ui/core/layout/widgets/sidebar_menu/widgets/expand_button_widget.dart';
import 'package:tune/ui/core/layout/widgets/sidebar_menu/widgets/logo_section_widget.dart';
import 'package:tune/ui/core/layout/widgets/sidebar_menu/widgets/menu_item_widget.dart';

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
    final layoutState = ref.watch(layoutStateNotifierProvider);
    final isExpanded = layoutState.isSidebarExpanded;

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
        icon: Icons.featured_play_list_outlined,
        route: '/featured',
      ),
      MenuItem(
        title: '音乐库',
        icon: Icons.library_music_outlined,
        route: '/library',
      ),
      MenuItem(
        title: '设置',
        icon: Icons.settings_outlined,
        route: '/settings',
      ),
    ];

    return Container(
      width: isExpanded ? 250 : 80,
      color: context.theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // 顶部Logo区域
          LogoSectionWidget(isExpanded: isExpanded),

          // 菜单项
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuItems.map((item) => MenuItemWidget(
                item: item,
                isExpanded: isExpanded,
                isSelected: currentRoute == item.route,
                onTap: () => onMenuItemSelected(item),
              )).toList(),
            ),
          ),

          // 用户信息区域
          if (isExpanded) ...[
            const Divider(),
            const _UserInfoWidget(),
          ],

          // 底部展开/收起按钮
          _buildExpandButton(context, ref, isExpanded),
        ],
      ),
    );
  }

  /// 构建展开/收缩按钮
  ///
  /// @param context 上下文
  /// @param ref WidgetRef
  /// @param isExpanded 是否展开
  Widget _buildExpandButton(BuildContext context, WidgetRef ref, bool isExpanded) {
    final layoutNotifier = ref.read(layoutStateNotifierProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 48.0, // 固定高度确保一致性
        child: InkWell(
          onTap: () {
            layoutNotifier.toggleSidebar();
          },
          child: Row(
            children: [
              // 固定宽度的图标区域，确保展开和收起时宽度一致
              SizedBox(
                width: 80.0,
                child: Center(
                  child: Icon(
                    isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                    size: 24.0,
                  ),
                ),
              ),
              // 文字区域，收起时隐藏
              if (isExpanded)
                Expanded(
                  child: Text(
                    '收起侧边栏',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 用户信息组件
class _UserInfoWidget extends StatelessWidget {
  const _UserInfoWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            child: Icon(Icons.person, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '用户名',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'user@example.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
