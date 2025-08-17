/// Layout模块状态数据模型
class LayoutState {
  final bool isSidebarExpanded;

  LayoutState({
    this.isSidebarExpanded = true,
  });

  /// 创建初始状态
  static LayoutState initial() {
    return LayoutState();
  }

  /// 复制并更新状态
  LayoutState copyWith({
    bool? isSidebarExpanded,
  }) {
    return LayoutState(
      isSidebarExpanded: isSidebarExpanded ?? this.isSidebarExpanded,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayoutState &&
        other.isSidebarExpanded == isSidebarExpanded;
  }

  @override
  int get hashCode => isSidebarExpanded.hashCode;
}