import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/user_profile.dart';

/// 用户菜单按钮组件
/// 负责显示用户菜单，包括个人信息和设置选项
class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.person),

      onSelected: (String result) {
        if (result == 'settings') {
          // 使用GoRouter导航到设置页面
          context.go('/settings');
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'profile',
          enabled: false,
          child: UserProfile(state: appBarState),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: Text(context.loc.settings), // 使用本地化字符串
        ),
      ],
    );
  }
}
