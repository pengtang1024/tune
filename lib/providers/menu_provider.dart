import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/router/app_router.dart';
import 'package:tune/utils/logger.dart';

/// 菜单状态Provider：管理当前选中的菜单索引（跨设备通用）
final menuStateProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref);
});

class MenuNotifier extends StateNotifier<MenuState> {
  final Ref ref;

  MenuNotifier(this.ref) : super(MenuState('/home')) {
    // 使用addPostFrameCallback来确保在构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncMenuWithRoute();
    });
  }

  /// 选中菜单并跳转对应路由
  void selectMenu(String path, bool isDesktop) {
    state = state.copyWith(path: path);
    // final menuItems = DeviceMenuItem.getByDevice(isDesktop);
    // final path = menuItems[index].path;
    // Log.info('Selected menu: ${menuItems[index].label}');
    ref.read(routerProvider).go(path);
  }

  /// 根据当前路由更新菜单状态（跨设备适配）
  void syncWithRoute(String currentPath) {
    state = state.copyWith(path: currentPath);
  }

  /// 初始化时同步路由状态
  void _syncMenuWithRoute() {
    try {
      final router = ref.read(routerProvider);
      final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
      Log.info('Current location: $currentLocation');
      // 同步菜单状态
      syncWithRoute(currentLocation);
    } catch (e, stackTrace) {
      Log.error('Error syncing menu with route: $e', stackTrace);
    }
  }
}

class MenuState {
  final String path;

  MenuState(this.path);

  MenuState copyWith({String? path}) {
    return MenuState(path ?? this.path);
  }
}
