import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 侧边栏菜单状态已移至layout_providers.dart
/// 此文件保留以确保向后兼容性，但应使用layoutStateNotifierProvider替代

/// 侧边栏菜单状态提供者（已弃用，请使用layoutStateNotifierProvider）
final sidebarMenuProvider = StateNotifierProvider.autoDispose((ref) {
  // 为了向后兼容，这里创建一个简单的状态提供者
  return _DeprecatedSidebarMenuNotifier();
});

class _DeprecatedSidebarMenuNotifier extends StateNotifier<bool> {
  _DeprecatedSidebarMenuNotifier() : super(true);

  void toggleExpanded() {
    state = !state;
  }
}
