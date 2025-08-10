import 'package:flutter/material.dart';

/// 桌面端侧边导航
class DesktopSideNav extends StatelessWidget {
  /// 当前索引
  final int currentIndex;

  /// 索引改变回调
  final Function(int)? onTap;

  /// 构造函数
  const DesktopSideNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_music),
          label: Text('Library'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
    );
  }
}