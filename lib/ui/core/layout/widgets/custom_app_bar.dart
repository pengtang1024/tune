import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/app_bar_title.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/back_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/clear_data_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/github_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/notification_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/play_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/user_menu_button.dart';

/// 自定义AppBar组件
/// 实现全局唯一的标题栏，所有页面共享同一实例
/// 该组件只负责串联各个子组件，不包含具体业务逻辑
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);

    return AppBar(
      // 标题
      title: const AppBarTitle(),

      // 返回按钮（仅在二级页面显示）
      leading: appBarState.showBackButton ? const BackButtonWidget() : null,

      // 操作按钮
      actions: [
        // 动态按钮（最右侧，从右到左排列）
        ...appBarState.dynamicActions,

        // 通知按钮
        const NotificationButton(),

        // 清理数据按钮（动态按钮左侧）
        const ClearDataButton(),

        // GitHub按钮（清理数据按钮左侧）
        const GitHubButton(),

        // 播放按钮（GitHub按钮左侧）
        const PlayButton(),


        // "我的"按钮（最左侧，但显示在最右边）
        const UserMenuButton(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
