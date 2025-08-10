import 'package:flutter/material.dart';

/// 移动端底部导航
class MobileBottomNav extends StatelessWidget {
  /// 当前索引
  final int currentIndex;

  /// 索引改变回调
  final Function(int)? onTap;

  /// 构造函数
  const MobileBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}