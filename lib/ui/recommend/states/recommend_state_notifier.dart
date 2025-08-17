import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/recommend/states/recommend_state.dart';

/// Recommend模块状态管理器
class RecommendStateNotifier extends StateNotifier<RecommendState> {
  RecommendStateNotifier() : super(RecommendState.initial());

  /// 加载推荐内容
  Future<void> loadRecommendContent() async {
    // 如果已经在加载中，则直接返回
    if (state.isLoading) return;

    // 设置为加载中状态
    state = RecommendState.loading();

    try {
      // 模拟异步加载操作
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 加载成功，更新状态
      state = RecommendState.initial();
    } catch (e) {
      // 加载失败，设置错误状态
      state = RecommendState.error('加载推荐内容失败');
    }
  }
}