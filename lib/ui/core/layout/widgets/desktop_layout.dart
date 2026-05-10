import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/providers/layout_providers.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar.dart';
import 'package:tune/ui/core/layout/widgets/desktop_menu/logo_section_widget.dart';
import 'package:tune/ui/core/layout/widgets/desktop_menu/menu_item_widget.dart';
import 'package:tune/ui/player/widgets/mini_player.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/user_info_widget.dart';

import 'desktop_menu/expand_button_widget.dart';

class DesktopLayout extends ConsumerWidget {
  final Widget child;
  final bool showMiniPlayer;

  const DesktopLayout({
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
    final isExpanded = ref.watch(layoutStateNotifierProvider).isExpanded;

    final sidebarWidth = isExpanded ? 220.0 : 72.0;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppDesignSystem.backgroundGradientDark
            : AppDesignSystem.backgroundGradientLight,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppDesignSystem.duration300,
            curve: AppDesignSystem.curveEaseInOut,
            width: sidebarWidth,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppDesignSystem.neutral900.withValues(alpha: 0.6)
                    : AppDesignSystem.neutral50.withValues(alpha: 0.6),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? AppDesignSystem.neutral800
                        : AppDesignSystem.neutral200,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  LogoSectionWidget(isExpanded: isExpanded),
                  const SizedBox(height: AppDesignSystem.spacing24),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.spacing8,
                      ),
                      children: DeviceMenuItem.desktop()
                          .asMap()
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppDesignSystem.spacing4,
                              ),
                              child: MenuItemWidget(
                                item: entry.value,
                                isExpanded: isExpanded,
                                isSelected: menuState.path == entry.value.path,
                                onTap: () {
                                  menuNotifier.selectMenu(
                                    entry.value.path,
                                    true,
                                  );
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (isExpanded) ...[
                    Divider(
                      color: isDark
                          ? AppDesignSystem.neutral800
                          : AppDesignSystem.neutral200,
                      height: 1,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(AppDesignSystem.spacing12),
                      child: UserInfoWidget(),
                    ),
                  ],
                  const ExpandButtonWidget(),
                  const SizedBox(height: AppDesignSystem.spacing8),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const CustomAppBar(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: AppDesignSystem.spacing16,
                      right: AppDesignSystem.spacing16,
                      top: AppDesignSystem.spacing12,
                      bottom: AppDesignSystem.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppDesignSystem.neutral900.withValues(alpha: 0.5)
                          : AppDesignSystem.neutral50.withValues(alpha: 0.5),
                      borderRadius: AppDesignSystem.borderRadius16,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppDesignSystem.borderRadius16,
                      child: Column(
                        children: [
                          Expanded(child: child),
                          if (showMiniPlayer) const MiniPlayer(),
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
    );
  }
}
