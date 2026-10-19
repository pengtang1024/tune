import 'package:tune/domain/models/song.dart';

/// 播放后端报告的一次错误。
///
/// 后端在加载远程地址失败时才会产生该事件；播放器据此把"卡在加载中"
/// 变成可见错误，而不是让界面一直等待。
class AudioPlayerError {
  final String message;
  final int? code;

  const AudioPlayerError({required this.message, this.code});

  @override
  String toString() => code == null ? message : '($code) $message';
}

/// 音频播放服务接口
abstract class AudioPlayerService {
  /// 初始化服务
  Future<void> init();

  /// 播放歌曲
  ///
  /// [localFilePath] 指向已经下载到本地的文件；传入后忽略歌曲的远程地址。
  Future<void> play(Song song, {String? localFilePath});

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

  /// 播放位置事件流（替代 UI 轮询）
  Stream<Duration> get positionStream;

  /// 音频时长事件流
  Stream<Duration?> get durationStream;

  /// 播放/暂停状态事件流
  Stream<bool> get playingStream;

  /// 当前曲目播放完成事件流
  Stream<void> get completionStream;

  /// 播放错误事件流
  ///
  /// 只在后端加载地址失败时触发，用于把"卡在加载中"变成可见错误。
  Stream<AudioPlayerError> get errorStream;

  /// 释放资源
  void dispose();
}
