import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/featured/states/featured_state.dart';

/// Featured模块状态管理器
class FeaturedStateNotifier extends StateNotifier<FeaturedState> {
  FeaturedStateNotifier() : super(FeaturedState.initial());

  /// 加载精选内容
  Future<void> loadFeaturedContent() async {
    // 如果已经在加载中，则直接返回
    if (state.isLoading) return;

    // 设置为加载中状态
    state = FeaturedState.loading();

    try {
      // 模拟异步加载操作
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 加载成功，更新状态
      state = FeaturedState.initial();
    } catch (e) {
      // 加载失败，设置错误状态
      state = FeaturedState.error('加载精选内容失败');
    }
  }
}