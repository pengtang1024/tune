import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/states/player_state_notifier.dart';

/// 播放器状态提供者
final playerStateNotifierProvider = StateNotifierProvider<PlayerStateNotifier, PlayerState>(
  (ref) => PlayerStateNotifier(ref),
);