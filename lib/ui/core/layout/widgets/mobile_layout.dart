import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/theme_extension.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/ui/core/layout/widgets/custom_app_bar.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/widgets/mini_player.dart';

class MobileLayout extends ConsumerWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final menuState = ref.watch(menuStateProvider);
    final menuNotifier = ref.read(menuStateProvider.notifier);
    final noSelected = context.theme.primaryColor.withValues(alpha: 0.6);
    final selected = context.theme.primaryColor;
    final playerState = ref.watch(playerStateNotifierProvider);
    final loc = context.loc;
    
    // 安全地获取选中的菜单项索引
    final mobileMenuItems = DeviceMenuItem.mobile();
    int selectedIndex = 0;
    try {
      selectedIndex = mobileMenuItems.firstWhere(
        (item) => item.path == menuState.path,
        orElse: () => mobileMenuItems.first,
      ).index;
    } catch (e) {
      // 如果找不到匹配项，使用默认的第一个菜单项
      selectedIndex = 0;
    }
    
    return Scaffold(
      appBar: const CustomAppBar(), // 全局唯一的标题栏
      body: Column(
        children: [
          // 内容展示区
          Expanded(
            child: child,
          ),
          // 迷你播放器（如果正在播放歌曲）
          if (playerState.currentSong != null) const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => menuNotifier.selectMenu(mobileMenuItems[index].path, false),
        destinations: mobileMenuItems.map((item)=> NavigationDestination(
          icon: Icon(item.icon, color: noSelected),
          selectedIcon: Icon(item.icon, color: selected),
          label: _getLocalizedLabel(loc, item.labelKey), // 使用本地化标签
          tooltip: _getLocalizedLabel(loc, item.labelKey), // 使用本地化工具提示
        )).toList(),
      ),
    );
  }

  /// 根据本地化键获取对应的本地化字符串
  static String _getLocalizedLabel(dynamic loc, String key) {
    // 使用反射或映射来获取本地化字符串
    switch (key) {
      case 'home':
        return loc.home;
      case 'recommend':
        return loc.recommend;
      case 'library':
        return loc.library;
      case 'featured':
        return loc.featured;
      case 'notification_test':
        return 'Notifications'; // 默认值，实际应该使用本地化
      default:
        return key;
    }
  }
}