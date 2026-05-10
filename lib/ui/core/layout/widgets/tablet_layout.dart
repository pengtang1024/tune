import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar.dart';
import 'package:tune/ui/player/widgets/mini_player.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class TabletLayout extends ConsumerWidget {
  final Widget child;
  final bool showMiniPlayer;

  const TabletLayout({
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

    return Column(
      children: [
        const CustomAppBar(),
        Expanded(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: DeviceMenuItem.desktop()
                    .indexWhere((item) => item.path == menuState.path),
                onDestinationSelected: (index) {
                  if (index >= 0 && index < DeviceMenuItem.desktop().length) {
                    menuNotifier.selectMenu(
                      DeviceMenuItem.desktop()[index].path,
                      true,
                    );
                  }
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor: isDark
                    ? AppDesignSystem.neutral900.withValues(alpha: 0.4)
                    : AppDesignSystem.neutral50.withValues(alpha: 0.4),
                indicatorColor: AppDesignSystem.primary.withValues(alpha: 0.12),
                selectedIconTheme: IconThemeData(
                  color: AppDesignSystem.primary,
                  size: AppDesignSystem.iconSize24,
                ),
                unselectedIconTheme: IconThemeData(
                  color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral500,
                  size: AppDesignSystem.iconSize20,
                ),
                destinations: DeviceMenuItem.desktop()
                    .map((item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.icon),
                          label: Text(
                            item.labelKey,
                            style: AppDesignSystem.textTheme.labelSmall,
                          ),
                        ))
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                          left: AppDesignSystem.spacing16,
                          right: AppDesignSystem.spacing16,
                          top: AppDesignSystem.spacing12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppDesignSystem.neutral900.withValues(alpha: 0.7)
                              : AppDesignSystem.neutral50.withValues(alpha: 0.7),
                          borderRadius: AppDesignSystem.borderRadius16,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: AppDesignSystem.borderRadius16,
                          child: child,
                        ),
                      ),
                    ),
                    if (showMiniPlayer) const MiniPlayer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
