import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 路由状态管理器
class RouterState extends ChangeNotifier {
  String _selectedMenuItem = '/';

  String get selectedMenuItem => _selectedMenuItem;

  void updateSelectedMenuItem(String path) {
    _selectedMenuItem = path;
    notifyListeners();
  }

  /// 根据路由路径获取对应的菜单索引
  int getSelectedIndex() {
    switch (_selectedMenuItem) {
      case '/':
        return 0;
      case '/recommend':
        return 1;
      case '/featured':
        return 2;
      case '/library':
        return 3;
      // 移除了设置菜单项的索引，因为设置按钮应该在AppBar上
      default:
        return 0;
    }
  }
}

/// 路由状态提供者
final routerProvider = ChangeNotifierProvider<RouterState>((ref) {
  return RouterState();
});