import 'package:flutter/material.dart';

/// 菜单项枚举：定义路由与菜单的映射关系
class DeviceMenuItem {
  final String path;
  final String label;
  final IconData icon;
  final int index;

  const DeviceMenuItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.index ,
  });

  /// 根据路由路径获取对应的菜单项
  /// 根据路由路径获取对应的菜单项（跨设备通用）
  static DeviceMenuItem? fromPath(String path) {
    // 先检查电脑端菜单
    for (var item in desktopMenuItems) {
      if (item.path == path) return item;
    }
    // 再检查手机端菜单
    for (var item in mobileMenuItems) {
      if (item.path == path) return item;
    }
    // 如果没有找到匹配的菜单项，返回null而不是抛出异常
    return null;
  }
  /// 根据设备类型获取菜单列表
  static List<DeviceMenuItem> getByDevice(bool isDesktop) {
    return isDesktop ? desktopMenuItems : mobileMenuItems;
  }
  static List<DeviceMenuItem> mobile(){
    return mobileMenuItems;
  }
  static List<DeviceMenuItem> desktop(){
    return desktopMenuItems;
  }

}
/// 手机端菜单项（数量较少）
const List<DeviceMenuItem> mobileMenuItems = [
  DeviceMenuItem(
    path: '/home',
    label: 'home', // 这里应该使用本地化键，而不是直接的字符串
    icon: Icons.home,
    index: 0,
  ),
  DeviceMenuItem(
    path: '/recommend',
    label: 'recommend', // 这里应该使用本地化键，而不是直接的字符串
    icon: Icons.explore,
    index: 1,
  ),
  DeviceMenuItem(
    path: '/library',
    label: 'library', // 这里应该使用本地化键，而不是直接的字符串
    icon: Icons.library_music,
    index: 2,
  ),
];

/// 电脑端菜单项（数量更多）
const List<DeviceMenuItem> desktopMenuItems = [
  DeviceMenuItem(
    path: '/home',
    label: 'home', // 这里应该使用本地化键，而不是直接的字符串
    icon: Icons.home,
    index: 0,
  ),
  DeviceMenuItem(
    path: '/recommend',
    label: 'recommend', // 这里应该使用本地化键，而不是直接的字符串
    icon: Icons.recommend,
    index: 1,
  ),
  DeviceMenuItem(
    path: '/featured',
    label: 'featured', // 这里应该使用本地化键，而不是直接的字符串
    icon: Icons.star,
    index: 2,
  ),
  DeviceMenuItem(
    path: '/library',
    label: 'library', // 这里应该使用本地化键，而不是直接的字符串
    icon: Icons.library_music,
    index: 3,
  ),
];