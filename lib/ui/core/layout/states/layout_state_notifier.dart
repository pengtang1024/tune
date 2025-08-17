import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/states/layout_state.dart';

/// Layout模块状态管理器
class LayoutStateNotifier extends StateNotifier<LayoutState> {
  LayoutStateNotifier() : super(LayoutState.initial());

  /// 切换侧边栏展开状态
  void toggleSidebar() {
    state = state.copyWith(isSidebarExpanded: !state.isSidebarExpanded);
  }
}