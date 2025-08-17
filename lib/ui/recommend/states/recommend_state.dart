/// Recommend模块状态数据模型
class RecommendState {
  final bool isLoading;
  final String errorMessage;

  RecommendState({
    this.isLoading = false,
    this.errorMessage = '',
  });

  /// 创建初始状态
  static RecommendState initial() {
    return RecommendState();
  }

  /// 创建加载中状态
  static RecommendState loading() {
    return RecommendState(isLoading: true);
  }

  /// 创建错误状态
  static RecommendState error(String message) {
    return RecommendState(errorMessage: message);
  }

  /// 复制并更新状态
  RecommendState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return RecommendState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendState &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(isLoading, errorMessage);
}