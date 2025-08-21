import 'dart:math';
import 'package:tune/ui/player/states/play_mode.dart';

/// 播放模式服务类
/// 负责处理播放模式相关的计算逻辑
class PlayModeService {
  /// 计算下一首歌曲的索引
  static int getNextIndex(int currentIndex, int playlistLength, PlayMode playMode) {
    if (playlistLength <= 0 || currentIndex < 0) {
      return -1;
    }

    switch (playMode) {
      case PlayMode.shuffle:
        // 随机播放模式
        int nextIndex = Random().nextInt(playlistLength);
        // 确保不会重复播放当前歌曲（如果播放列表长度大于1）
        if (nextIndex == currentIndex && playlistLength > 1) {
          nextIndex = (nextIndex + 1) % playlistLength;
        }
        return nextIndex;
        
      case PlayMode.repeatOne:
        // 单曲循环模式，保持当前索引
        return currentIndex;
        
      default:
        // 顺序播放模式
        return (currentIndex + 1) % playlistLength;
    }
  }

  /// 计算上一首歌曲的索引
  static int getPreviousIndex(int currentIndex, int playlistLength, PlayMode playMode) {
    if (playlistLength <= 0 || currentIndex < 0) {
      return -1;
    }

    switch (playMode) {
      case PlayMode.shuffle:
        // 随机播放模式
        int previousIndex = Random().nextInt(playlistLength);
        // 确保不会重复播放当前歌曲（如果播放列表长度大于1）
        if (previousIndex == currentIndex && playlistLength > 1) {
          previousIndex = (previousIndex + 1) % playlistLength;
        }
        return previousIndex;
        
      case PlayMode.repeatOne:
        // 单曲循环模式，保持当前索引
        return currentIndex;
        
      default:
        // 顺序播放模式
        return (currentIndex - 1 + playlistLength) % playlistLength;
    }
  }

  /// 获取播放模式的下一个模式
  static PlayMode getNextPlayMode(PlayMode currentMode) {
    switch (currentMode) {
      case PlayMode.sequential:
        return PlayMode.shuffle;
      case PlayMode.shuffle:
        return PlayMode.repeatOne;
      case PlayMode.repeatOne:
        return PlayMode.sequential;
    }
  }
}