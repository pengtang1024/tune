import 'dart:async';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/utils/logger.dart';

/// 资源管理扩展
/// 负责处理播放器的资源释放和清理
extension ResourceManagementExtension on StreamSubscription? {
  /// 安全取消订阅
  void safeCancel() {
    try {
      if (this != null) {
        this!.cancel();
        Log.info('资源订阅取消成功');
      }
    } catch (e, stackTrace) {
      Log.error('资源订阅取消失败: $e\nStack trace: $stackTrace');
    }
  }
}

extension AudioPlayerResourceManagement on AudioPlayerService {
  /// 安全释放播放器资源
  void safeDispose() {
    try {
      dispose();
      Log.info('音频播放器资源释放成功');
    } catch (e, stackTrace) {
      Log.error('音频播放器资源释放失败: $e\nStack trace: $stackTrace');
    }
  }
}

/// 播放器状态扩展
extension PlayerStateResourceManagement on PlayerState {
  /// 创建初始状态
  static PlayerState createInitial() {
    return PlayerState.initial();
  }

  /// 检查状态是否需要清理资源
  bool shouldCleanupResources() {
    return isError || (currentSong == null && !isPlaying);
  }

  /// 获取状态清理提示
  String getCleanupHint() {
    if (isError) return '播放器遇到错误，需要重置';
    if (currentSong == null && !isPlaying) return '播放器处于空闲状态';
    return '播放器正在运行';
  }
}
