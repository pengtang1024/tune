import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/states/playback_settings_state.dart';
import 'package:tune/ui/core/settings/states/playback_settings_state_notifier.dart';

/// 播放设置状态提供者
final playbackSettingsProvider = StateNotifierProvider<PlaybackSettingsStateNotifier, PlaybackSettingsState>(
  (ref) => PlaybackSettingsStateNotifier(),
);