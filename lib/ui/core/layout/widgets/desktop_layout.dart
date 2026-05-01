import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/providers/layout_providers.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar.dart';
import 'package:tune/ui/core/layout/widgets/desktop_menu/logo_section_widget.dart';
import 'package:tune/ui/core/layout/widgets/desktop_menu/menu_item_widget.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/widgets/mini_player.dart';
import 'package:tune/ui/widgets/user_info_widget.dart';
import 'package:tune/ui/theme/app_design_system.dart';

import 'desktop_menu/expand_button_widget.dart';

/// 现代化桌面端布局
/// 提供优雅的侧边栏和内容区域设计
class DesktopLayout extends ConsumerWidget {
  final Widget child;

  const DesktopLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final menuState = ref.watch(menuStateProvider);
    final menuNotifier = ref.read(menuStateProvider.notifier);
    final isExpanded = ref.watch(layoutStateNotifierProvider).isExpanded;
    final playerState = ref.watch(playerStateNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: theme.brightness == Brightness.dark
              ? AppDesignSystem.backgroundGradientDark
              : AppDesignSystem.backgroundGradientLight,
        ),
        child: Row(
          children: [
            // 现代化侧边栏
            Container(
              width: isExpanded ? 280 : 80,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppDesignSystem.neutral900
                    : AppDesignSystem.neutral50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
                border: Border(
                  right: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? AppDesignSystem.neutral800
                        : AppDesignSystem.neutral200,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // 顶部Logo区域
                  LogoSectionWidget(isExpanded: isExpanded),

                  const SizedBox(height: AppDesignSystem.spacing16),

                  // 菜单项
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: DeviceMenuItem.desktop()
                          .asMap()
                          .entries
                          .map(
                            (entry) => MenuItemWidget(
                              item: entry.value,
                              isExpanded: isExpanded,
                              isSelected: menuState.path == entry.value.path,
                              onTap: () {
                                menuNotifier.selectMenu(entry.value.path, true);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: AppDesignSystem.spacing16),

                  // 用户信息区域
                  if (isExpanded) ...[
                    Divider(
                      color: theme.brightness == Brightness.dark
                          ? AppDesignSystem.neutral800
                          : AppDesignSystem.neutral200,
                      height: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                      child: const UserInfoWidget(),
                    ),
                  ],

                  // 底部展开/收起按钮
                  const ExpandButtonWidget(),
                ],
              ),
            ),
            
            // 内容区域
            Expanded(
              child: Column(
                children: [
                  // 全局唯一的标题栏
                  const CustomAppBar(),
                  
                  // 主要内容区域
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(AppDesignSystem.spacing16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
            ? AppDesignSystem.neutral900.withOpacity(0.9)
            : AppDesignSystem.neutral50.withOpacity(0.9),
                        borderRadius: AppDesignSystem.borderRadius16,
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? AppDesignSystem.neutral800
                              : AppDesignSystem.neutral200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: AppDesignSystem.borderRadius16,
                        child: Column(
                          children: [
                            // 主要内容
                            Expanded(child: child),
                            
                            // 迷你播放器（如果正在播放歌曲）
                            if (playerState.currentSong != null) const MiniPlayer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
