import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/theme_extension.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/providers/layout_providers.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar.dart';
import 'package:tune/ui/core/layout/widgets/desktop_menu/logo_section_widget.dart';
import 'package:tune/ui/core/layout/widgets/desktop_menu/menu_item_widget.dart';
import 'package:tune/ui/widgets/user_info_widget.dart';

import 'desktop_menu/expand_button_widget.dart';

class DesktopLayout extends ConsumerWidget {
  final Widget child;

  const DesktopLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuStateProvider);
    final menuNotifier = ref.read(menuStateProvider.notifier);
    final isExpanded = ref.watch(layoutStateNotifierProvider).isExpanded;
    return Row(
      children: [
        // 侧边栏菜单
        Container(
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
                  children: DeviceMenuItem.desktop()
                      .map(
                        (item) => MenuItemWidget(
                          item: item,
                          isExpanded: isExpanded,
                          isSelected: menuState.path == item.path,
                          onTap: () => {
                            menuNotifier.selectMenu(item.path, true),
                          },
                        ),
                      )
                      .toList(),
                ),
              ),

              // 用户信息区域
              if (isExpanded) ...[const Divider(), const UserInfoWidget()],

              // 底部展开/收起按钮
              ExpandButtonWidget(isExpanded: isExpanded),
            ],
          ),
        ),
        // 内容区
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
