import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/states/play_mode.dart';

/// 播放器状态扩展
/// 负责处理播放器状态的创建和更新
extension PlayerStateExtension on PlayerState {
  /// 创建加载状态
  static PlayerState loading(Song song) {
    return PlayerState.loading(song);
  }

  /// 创建播放状态
  static PlayerState playing(
    Song song,
    Duration position,
    Duration duration,
    double speed,
  ) {
    return PlayerState.playing(
      song,
      position,
      duration,
      speed,
    );
  }

  /// 创建错误状态
  static PlayerState error(String error) {
    return PlayerState.error(error);
  }

  /// 创建初始状态
  static PlayerState initial() {
    return PlayerState.initial();
  }
}

/// 播放器状态更新扩展
/// 负责处理播放器状态的更新逻辑
extension PlayerStateUpdateExtension on PlayerState {
  /// 检查是否为播放状态
  bool get isPlayingState => isPlaying && !isLoading && !isError;

  /// 检查是否为加载状态
  bool get isLoadingState => isLoading && currentSong != null;

  /// 检查是否为错误状态
  bool get isErrorState => isError;

  /// 检查是否为初始状态
  bool get isInitialState => currentSong == null && !isPlaying && !isLoading && !isError;

  /// 获取状态描述
  String get stateDescription {
    if (isError) return '错误状态';
    if (isLoading) return '加载中';
    if (isPlaying) return '播放中';
    return '初始状态';
  }

  /// 检查状态是否有效
  bool get isValidState => currentSong != null;

  /// 复制状态并更新播放模式
  PlayerState copyWithPlayMode(PlayMode playMode) {
    return copyWith(playMode: playMode);
  }

  /// 复制状态并更新播放位置
  PlayerState copyWithPosition(int position) {
    return copyWith(position: Duration(milliseconds: position));
  }
}
