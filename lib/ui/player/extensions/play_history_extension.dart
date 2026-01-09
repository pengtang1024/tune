import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// 播放历史记录管理扩展
/// 负责处理播放历史记录的增删改查操作
extension PlayHistoryExtension on List<Song> {
  static const int _maxHistorySize = 50;

  /// 添加歌曲到历史记录
  void addToHistory(Song song) {
    try {
      // 如果历史记录中已存在该歌曲，先移除
      remove(song);
      
      // 添加到开头
      insert(0, song);
      
      // 保持最大历史记录数量
      if (length > _maxHistorySize) {
        removeRange(_maxHistorySize, length);
      }
      
      Log.info('添加到播放历史: ${song.title} (历史记录数量: $length)');
    } catch (e, stackTrace) {
      Log.error('添加到播放历史失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 清空历史记录
  void clearHistory() {
    try {
      clear();
      Log.info('清空播放历史记录');
    } catch (e, stackTrace) {
      Log.error('清空播放历史记录失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 获取历史记录数量
  int get historyCount => length;

  /// 检查是否达到最大历史记录数量
  bool get isAtMaxCapacity => length >= _maxHistorySize;
}
