import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/states/play_mode.dart';

/// 播放器状态数据模型
class PlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final PlayMode playMode;
  final String errorMessage;

  PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.playMode = PlayMode.sequential,
    this.errorMessage = '',
  });

  /// 创建初始状态
  static PlayerState initial() {
    return PlayerState();
  }

  /// 创建加载中状态
  static PlayerState loading(Song song) {
    return PlayerState(
      currentSong: song,
      isPlaying: false,
    );
  }

  /// 创建播放状态
  static PlayerState playing(Song song, Duration position, Duration duration, double speed) {
    return PlayerState(
      currentSong: song,
      isPlaying: true,
      position: position,
      duration: duration,
      speed: speed,
    );
  }

  /// 创建暂停状态
  static PlayerState paused(Song song, Duration position, Duration duration, double speed) {
    return PlayerState(
      currentSong: song,
      isPlaying: false,
      position: position,
      duration: duration,
      speed: speed,
    );
  }

  /// 创建错误状态
  static PlayerState error(String message) {
    return PlayerState(errorMessage: message);
  }

  /// 复制并更新状态
  PlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    PlayMode? playMode,
    String? errorMessage,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      playMode: playMode ?? this.playMode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 检查是否处于加载状态
  bool get isLoading => currentSong != null && 
                       errorMessage.isEmpty && 
                       !isPlaying && 
                       position == Duration.zero && 
                       duration == Duration.zero;

  /// 检查是否处于错误状态
  bool get isError => errorMessage.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerState &&
        other.currentSong == currentSong &&
        other.isPlaying == isPlaying &&
        other.position == position &&
        other.duration == duration &&
        other.volume == volume &&
        other.speed == speed &&
        other.playMode == playMode &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        currentSong,
        isPlaying,
        position,
        duration,
        volume,
        speed,
        playMode,
        errorMessage,
      );
}