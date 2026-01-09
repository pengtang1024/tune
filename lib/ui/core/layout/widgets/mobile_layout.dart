import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/widgets/mini_player.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化移动端布局
/// 提供流畅的移动端用户体验
class MobileLayout extends ConsumerWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuState = ref.watch(menuStateProvider);
    final menuNotifier = ref.read(menuStateProvider.notifier);
    final playerState = ref.watch(playerStateNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppDesignSystem.backgroundGradientDark
              : AppDesignSystem.backgroundGradientLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 全局唯一的标题栏
              const CustomAppBar(),
              
              // 内容展示区
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                  child: ClipRRect(
                    borderRadius: AppDesignSystem.borderRadius16,
                    child: child,
                  ),
                ),
              ),
              
              // 迷你播放器（如果正在播放歌曲）
              if (playerState.currentSong != null) const MiniPlayer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: DeviceMenuItem.mobile()
              .firstWhere((item) => item.path == menuState.path)
              .index,
          onDestinationSelected: (index) {
            menuNotifier.selectMenu(DeviceMenuItem.mobile()[index].path, false);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: DeviceMenuItem.mobile()
              .map((item) => NavigationDestination(
                icon: Icon(
                  item.icon,
                  color: isDark 
                      ? AppDesignSystem.neutral500
                      : AppDesignSystem.neutral600,
                ),
                selectedIcon: Icon(
                  item.icon,
                  color: AppDesignSystem.primary,
                ),
                label: item.label,
                tooltip: item.label,
              ))
              .toList(),
        ),
      ),
    );
  }
}