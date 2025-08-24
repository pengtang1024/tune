import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/theme_extension.dart';
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
        selectedIndex: DeviceMenuItem.mobile().firstWhere((item) => item.path == menuState.path).index,
        onDestinationSelected: (index) => menuNotifier.selectMenu(DeviceMenuItem.mobile()[index].path, false),
        destinations: DeviceMenuItem.mobile().map((item)=> NavigationDestination(
          icon: Icon(item.icon, color: noSelected),
          selectedIcon: Icon(item.icon, color: selected),
          label: item.label,
          tooltip: item.label,
        )).toList(),
      ),
    );
  }
}