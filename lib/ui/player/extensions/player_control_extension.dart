import 'dart:async';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// 播放器状态信息数据类
class PlayerStateInfo {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;

  const PlayerStateInfo({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.speed,
  });

  factory PlayerStateInfo.empty() {
    return const PlayerStateInfo(
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
      speed: 1.0,
    );
  }

  /// 获取位置的毫秒数
  int get positionInMilliseconds => position.inMilliseconds;
  
  /// 获取时长的毫秒数
  int get durationInMilliseconds => duration.inMilliseconds;

  /// 检查状态是否发生变化
  bool hasChanged(PlayerStateInfo other) {
    return isPlaying != other.isPlaying ||
           position != other.position ||
           duration != other.duration ||
           speed != other.speed;
  }
}

/// 播放器控制扩展
/// 负责处理播放器的核心控制逻辑
extension PlayerControlExtension on AudioPlayerService {
  /// 创建位置监听流
  Stream<Duration> createPositionStream() {
    return Stream.periodic(const Duration(milliseconds: 100))
        .map((_) => currentPosition)
        .distinct();
  }

  /// 播放歌曲并处理错误
  Future<void> safePlay(Song song) async {
    try {
      await play(song);
      Log.info('歌曲播放成功: ${song.title}');
    } catch (e, stackTrace) {
      Log.error('播放歌曲失败: ${song.title}, 错误: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// 停止播放并处理错误
  Future<void> safeStop() async {
    try {
      await stop();
      Log.info('停止播放成功');
    } catch (e, stackTrace) {
      Log.error('停止播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// 跳转到指定位置并处理错误
  Future<void> safeSeekTo(Duration position) async {
    try {
      await seekTo(position);
      Log.info('跳转到位置: ${position.inMilliseconds} ms');
    } catch (e, stackTrace) {
      Log.error('跳转到指定位置失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// 设置音量并处理错误
  Future<void> safeSetVolume(double volume) async {
    try {
      await setVolume(volume);
      Log.info('音量设置为: $volume');
    } catch (e, stackTrace) {
      Log.error('设置音量失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// 设置播放速度并处理错误
  Future<void> safeSetSpeed(double speed) async {
    try {
      await setSpeed(speed);
      Log.info('播放速度设置为: $speed');
    } catch (e, stackTrace) {
      Log.error('设置播放速度失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// 获取播放状态信息
  PlayerStateInfo getPlayerStateInfo() {
    try {
      return PlayerStateInfo(
        isPlaying: isPlaying,
        position: currentPosition,
        duration: duration,
        speed: speed,
      );
    } catch (e, stackTrace) {
      Log.error('获取播放状态信息失败: $e\nStack trace: $stackTrace');
      return PlayerStateInfo.empty();
    }
  }

  /// 暂停播放
  Future<void> safePause() async {
    try {
      await pause();
      Log.info('暂停播放成功');
    } catch (e, stackTrace) {
      Log.error('暂停播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// 继续播放
  Future<void> safeResume() async {
    try {
      await resume();
      Log.info('继续播放成功');
    } catch (e, stackTrace) {
      Log.error('继续播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }
}
