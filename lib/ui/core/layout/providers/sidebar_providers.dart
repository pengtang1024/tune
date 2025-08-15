import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/view_model/sidebar_view_model.dart';


/// 侧边栏菜单状态提供者
final sidebarMenuProvider = StateNotifierProvider<SidebarMenuNotifier, SidebarMenuState>((ref) {
  return SidebarMenuNotifier();
});
