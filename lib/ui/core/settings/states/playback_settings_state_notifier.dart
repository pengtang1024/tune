import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/states/playback_settings_state.dart';

/// 播放设置状态管理器
class PlaybackSettingsStateNotifier extends StateNotifier<PlaybackSettingsState> {
  PlaybackSettingsStateNotifier() : super(PlaybackSettingsState.initial());

  /// 更新播放模式
  void updatePlayMode(String playMode) {
    state = state.copyWith(playMode: playMode);
  }

  /// 更新音质设置
  void updateAudioQuality(String audioQuality) {
    state = state.copyWith(audioQuality: audioQuality);
  }

  /// 更新耳机断开连接时是否暂停播放
  void updatePauseWhenHeadsetDisconnected(bool pause) {
    state = state.copyWith(pauseWhenHeadsetDisconnected: pause);
  }

  /// 更新播放模式
  void updatePlaybackMode(String mode) {
    state = state.copyWith(playMode: mode);
  }

  /// 切换均衡器
  void toggleEqualizer(bool value) {
    state = state.copyWith(isEqualizerEnabled: value);
  }

  /// 切换低音增强
  void toggleBassBoost(bool value) {
    state = state.copyWith(isBassBoostEnabled: value);
  }

  /// 切换空间音频
  void toggleSpatialAudio(bool value) {
    state = state.copyWith(isSpatialAudioEnabled: value);
  }

  /// 保存设置
  void saveSettings() {
    // TODO: 实现保存设置到持久化存储的逻辑
  }
}