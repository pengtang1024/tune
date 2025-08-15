
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/menu_item.dart';

/// 侧边栏菜单状态
class SidebarMenuState {
  final bool isExpanded;
  final MenuItem? selectedMenuItem;

  SidebarMenuState({
    required this.isExpanded,
    this.selectedMenuItem,
  });

  SidebarMenuState copyWith({
    bool? isExpanded,
    MenuItem? selectedMenuItem,
  }) {
    return SidebarMenuState(
      isExpanded: isExpanded ?? this.isExpanded,
      selectedMenuItem: selectedMenuItem ?? this.selectedMenuItem,
    );
  }

  static SidebarMenuState initial() {
    return SidebarMenuState(
      isExpanded: true,
      selectedMenuItem: null,
    );
  }
}

/// 侧边栏菜单状态提供者
class SidebarMenuNotifier extends StateNotifier<SidebarMenuState> {
  SidebarMenuNotifier() : super(SidebarMenuState.initial());

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setSelectedMenuItem(MenuItem? item) {
    state = state.copyWith(selectedMenuItem: item);
  }
}
