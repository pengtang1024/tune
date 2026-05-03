import 'package:flutter/material.dart';

/// 菜单项枚举：定义路由与菜单的映射关系
class DeviceMenuItem {
  final String path;
  final String labelKey;
  final IconData icon;
  final int index;

  const DeviceMenuItem({
    required this.path,
    required this.labelKey,
    required this.icon,
    required this.index,
  });

  static DeviceMenuItem? fromPath(String path) {
    for (var item in desktopMenuItems) {
      if (item.path == path) return item;
    }
    for (var item in mobileMenuItems) {
      if (item.path == path) return item;
    }
    return null;
  }

  static List<DeviceMenuItem> getByDevice(bool isDesktop) {
    return isDesktop ? desktopMenuItems : mobileMenuItems;
  }

  static List<DeviceMenuItem> mobile() => mobileMenuItems;
  static List<DeviceMenuItem> desktop() => desktopMenuItems;
}

/// 简化的手机端菜单（4个核心功能）
const List<DeviceMenuItem> mobileMenuItems = [
  DeviceMenuItem(
    path: '/home',
    labelKey: 'home',
    icon: Icons.home,
    index: 0,
  ),
  DeviceMenuItem(
    path: '/library',
    labelKey: 'library',
    icon: Icons.library_music,
    index: 1,
  ),
  DeviceMenuItem(
    path: '/player',
    labelKey: 'player',
    icon: Icons.play_circle,
    index: 2,
  ),
  DeviceMenuItem(
    path: '/settings',
    labelKey: 'settings',
    icon: Icons.settings,
    index: 3,
  ),
];

/// 简化的电脑端菜单（4个核心功能）
const List<DeviceMenuItem> desktopMenuItems = [
  DeviceMenuItem(
    path: '/home',
    labelKey: 'home',
    icon: Icons.home,
    index: 0,
  ),
  DeviceMenuItem(
    path: '/library',
    labelKey: 'library',
    icon: Icons.library_music,
    index: 1,
  ),
  DeviceMenuItem(
    path: '/player',
    labelKey: 'player',
    icon: Icons.play_circle,
    index: 2,
  ),
  DeviceMenuItem(
    path: '/settings',
    labelKey: 'settings',
    icon: Icons.settings,
    index: 3,
  ),
];
