import 'package:tune/domain/models/song.dart';

/// 音频播放服务接口
abstract class AudioPlayerService {
  /// 初始化服务
  Future<void> init();

  /// 播放歌曲
  Future<void> play(Song song);

  /// 暂停播放
  Future<void> pause();

  /// 继续播放
  Future<void> resume();

  /// 停止播放
  Future<void> stop();

  /// 跳转到指定位置
  Future<void> seekTo(Duration position);

  /// 设置音量
  Future<void> setVolume(double volume);

  /// 设置播放速度
  Future<void> setSpeed(double speed);

  /// 获取当前播放位置
  Duration get currentPosition;

  /// 获取音频总时长
  Duration get duration;

  /// 是否正在播放
  bool get isPlaying;

  /// 获取当前播放速度
  double get speed;

  /// 释放资源
  void dispose();
}