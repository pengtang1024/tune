import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/featured/states/featured_state.dart';
import 'package:tune/ui/featured/states/featured_state_notifier.dart';

/// Featured模块状态提供者
final featuredStateNotifierProvider = StateNotifierProvider<FeaturedStateNotifier, FeaturedState>(
  (ref) => FeaturedStateNotifier(),
);