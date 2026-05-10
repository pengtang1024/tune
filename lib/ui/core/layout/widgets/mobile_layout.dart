import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar.dart';
import 'package:tune/ui/player/widgets/mini_player.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class MobileLayout extends ConsumerWidget {
  final Widget child;
  final bool showMiniPlayer;

  const MobileLayout({
    super.key,
    required this.child,
    this.showMiniPlayer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuState = ref.watch(menuStateProvider);
    final menuNotifier = ref.read(menuStateProvider.notifier);
    final items = DeviceMenuItem.mobile();
    final selectedIndex = items.indexWhere((item) => item.path == menuState.path);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppDesignSystem.backgroundGradientDark
              : AppDesignSystem.backgroundGradientLight,
        ),
        child: Column(
          children: [
            const CustomAppBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppDesignSystem.duration200,
                child: child,
              ),
            ),
            if (showMiniPlayer) const MiniPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppDesignSystem.neutral900
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
          onDestinationSelected: (index) {
            if (index >= 0 && index < items.length) {
              menuNotifier.selectMenu(items[index].path, false);
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppDesignSystem.primary.withValues(alpha: 0.12),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: AppDesignSystem.borderRadius12,
          ),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: items
              .map((item) => NavigationDestination(
                    icon: Icon(
                      item.icon,
                      color: isDark
                          ? AppDesignSystem.neutral500
                          : AppDesignSystem.neutral400,
                      size: AppDesignSystem.iconSize24,
                    ),
                    selectedIcon: Icon(
                      item.icon,
                      color: AppDesignSystem.primary,
                      size: AppDesignSystem.iconSize24,
                    ),
                    label: item.labelKey,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
