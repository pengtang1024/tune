/// Layout模块状态数据模型
class LayoutState {
  final bool isExpanded;

  LayoutState({
    this.isExpanded = true,
  });

  /// 创建初始状态
  static LayoutState initial() {
    return LayoutState();
  }

  /// 复制并更新状态
  LayoutState copyWith({
    bool? isExpanded,
  }) {
    return LayoutState(
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayoutState &&
        other.isExpanded == isExpanded;
  }

  @override
  int get hashCode => isExpanded.hashCode;
}
