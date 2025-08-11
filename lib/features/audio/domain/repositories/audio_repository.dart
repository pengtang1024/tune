abstract class AudioRepository {
  /// 播放指定音频
  Future<void> playAudio(String audioPath);
  
  /// 暂停音频播放
  Future<void> pauseAudio();
  
  /// 停止音频播放
  Future<void> stopAudio();
  
  /// 获取当前音频播放状态
  Future<bool> isAudioPlaying();
  
  /// 设置音频播放位置
  Future<void> setPlaybackPosition(Duration position);
  
  /// 获取当前播放位置
  Future<Duration> getPlaybackPosition();
}
