import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/states/layout_state.dart';
import 'package:tune/ui/core/layout/states/layout_state_notifier.dart';

/// Layout模块状态提供者
final layoutStateNotifierProvider = StateNotifierProvider<LayoutStateNotifier, LayoutState>(
  (ref) => LayoutStateNotifier(),
);