import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/app_bar_title.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/back_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/clear_data_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/github_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/notification_button.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar/user_menu_button.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);

    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const AppBarTitle(),
      leading: appBarState.showBackButton ? const BackButtonWidget() : null,
      actions: [
        ...appBarState.dynamicActions,
        IconButton(icon: const Icon(Icons.search, size: AppDesignSystem.iconSize24), onPressed: () {}),
        const NotificationButton(),
        const ClearDataButton(),
        const GitHubButton(),
        const UserMenuButton(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
