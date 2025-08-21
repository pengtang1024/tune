/// 播放设置状态
class PlaybackSettingsState {
  final String playMode;
  final String audioQuality;
  final bool pauseWhenHeadsetDisconnected;
  final bool isEqualizerEnabled;
  final bool isBassBoostEnabled;
  final bool isSpatialAudioEnabled;

  PlaybackSettingsState({
    required this.playMode,
    required this.audioQuality,
    required this.pauseWhenHeadsetDisconnected,
    required this.isEqualizerEnabled,
    required this.isBassBoostEnabled,
    required this.isSpatialAudioEnabled,
  });

  /// 创建初始状态
  static PlaybackSettingsState initial() {
    return PlaybackSettingsState(
      playMode: 'sequence',
      audioQuality: 'high',
      pauseWhenHeadsetDisconnected: true,
      isEqualizerEnabled: false,
      isBassBoostEnabled: false,
      isSpatialAudioEnabled: false,
    );
  }

  /// 创建副本并更新指定字段
  PlaybackSettingsState copyWith({
    String? playMode,
    String? audioQuality,
    bool? pauseWhenHeadsetDisconnected,
    bool? isEqualizerEnabled,
    bool? isBassBoostEnabled,
    bool? isSpatialAudioEnabled,
  }) {
    return PlaybackSettingsState(
      playMode: playMode ?? this.playMode,
      audioQuality: audioQuality ?? this.audioQuality,
      pauseWhenHeadsetDisconnected: pauseWhenHeadsetDisconnected ?? this.pauseWhenHeadsetDisconnected,
      isEqualizerEnabled: isEqualizerEnabled ?? this.isEqualizerEnabled,
      isBassBoostEnabled: isBassBoostEnabled ?? this.isBassBoostEnabled,
      isSpatialAudioEnabled: isSpatialAudioEnabled ?? this.isSpatialAudioEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaybackSettingsState &&
        other.playMode == playMode &&
        other.audioQuality == audioQuality &&
        other.pauseWhenHeadsetDisconnected == pauseWhenHeadsetDisconnected &&
        other.isEqualizerEnabled == isEqualizerEnabled &&
        other.isBassBoostEnabled == isBassBoostEnabled &&
        other.isSpatialAudioEnabled == isSpatialAudioEnabled;
  }

  @override
  int get hashCode => Object.hash(
        playMode,
        audioQuality,
        pauseWhenHeadsetDisconnected,
        isEqualizerEnabled,
        isBassBoostEnabled,
        isSpatialAudioEnabled,
      );
}