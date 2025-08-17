import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/recommend/states/recommend_state.dart';
import 'package:tune/ui/recommend/states/recommend_state_notifier.dart';

/// Recommend模块状态提供者
final recommendStateNotifierProvider = StateNotifierProvider<RecommendStateNotifier, RecommendState>(
  (ref) => RecommendStateNotifier(),
);