import 'dart:math';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/utils/logger.dart';

/// 播放列表管理器扩展
/// 负责处理播放列表的增删改查操作
extension PlaylistManagerExtension on List<Song> {
  /// 获取随机索引
  int getRandomIndex() {
    if (isEmpty) return -1;
    return Random().nextInt(length);
  }

  /// 获取下一个索引
  int getNextIndex(int currentIndex, PlayMode playMode) {
    if (isEmpty) return -1;

    switch (playMode) {
      case PlayMode.sequential:
        return (currentIndex + 1) % length;
      case PlayMode.repeatOne:
        return currentIndex;
      case PlayMode.shuffle:
        return getRandomIndex();
    }
  }

  /// 获取上一个索引
  int getPreviousIndex(int currentIndex, PlayMode playMode) {
    if (isEmpty) return -1;

    switch (playMode) {
      case PlayMode.sequential:
        return (currentIndex - 1 + length) % length;
      case PlayMode.repeatOne:
        return currentIndex;
      case PlayMode.shuffle:
        return getRandomIndex();
    }
  }

  /// 验证索引有效性
  bool isValidIndex(int index) {
    return index >= 0 && index < length;
  }

  /// 安全获取元素
  Song? safeGet(int index) {
    return isValidIndex(index) ? this[index] : null;
  }

  /// 添加元素并记录日志
  void safeAdd(Song song, {String? context}) {
    try {
      add(song);
      Log.info('${context ?? "添加歌曲"}到播放列表: ${song.title}');
    } catch (e, stackTrace) {
      Log.error('${context ?? "添加歌曲"}到播放列表失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 安全移除元素
  Song? safeRemoveAt(int index, {String? context}) {
    try {
      if (isValidIndex(index)) {
        final song = removeAt(index);
        Log.info('${context ?? "移除歌曲"}从播放列表: ${song.title}');
        return song;
      }
      return null;
    } catch (e, stackTrace) {
      Log.error('${context ?? "移除歌曲"}从播放列表失败: $e\nStack trace: $stackTrace');
      return null;
    }
  }

  /// 清空列表并记录日志
  void safeClear({String? context}) {
    try {
      clear();
      Log.info('${context ?? "清空播放列表"}成功');
    } catch (e, stackTrace) {
      Log.error('${context ?? "清空播放列表"}失败: $e\nStack trace: $stackTrace');
    }
  }
}
