import 'package:flutter/material.dart';

/// Web端顶部导航
class WebTopNav extends StatelessWidget {
  /// 当前索引
  final int currentIndex;

  /// 索引改变回调
  final Function(int)? onTap;

  /// 构造函数
  const WebTopNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_music),
          label: 'Library',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}