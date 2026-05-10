import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Tune', style: AppDesignSystem.textTheme.titleLarge?.copyWith(fontWeight: AppDesignSystem.fontWeightBold)),
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => context.go('/search')),
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.go('/notifications')),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
