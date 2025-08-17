/// Featured模块状态数据模型
class FeaturedState {
  final bool isLoading;
  final String errorMessage;

  FeaturedState({
    this.isLoading = false,
    this.errorMessage = '',
  });

  /// 创建初始状态
  static FeaturedState initial() {
    return FeaturedState();
  }

  /// 创建加载中状态
  static FeaturedState loading() {
    return FeaturedState(isLoading: true);
  }

  /// 创建错误状态
  static FeaturedState error(String message) {
    return FeaturedState(errorMessage: message);
  }

  /// 复制并更新状态
  FeaturedState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return FeaturedState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeaturedState &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(isLoading, errorMessage);
}