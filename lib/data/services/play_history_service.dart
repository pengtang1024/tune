import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../domain/models/song.dart';
import '../../domain/models/song_adapter.dart';

/// 播放历史存储服务
class PlayHistoryService {
  static const int _maxHistorySize = 50; // 最大历史记录数量

  PlayHistoryService._();

  static final PlayHistoryService _instance = PlayHistoryService._();

  factory PlayHistoryService() => _instance;

  Box<Song>? _playHistoryBox;

  /// 初始化Hive
  Future<void> init() async {
    // 注册适配器
    Hive.registerAdapter(SongAdapter());

    // 打开播放历史 Box
    _playHistoryBox = await Hive.openBox<Song>('play_history');
  }

  /// 获取播放历史盒子
  Future<Box<Song>> get _historyBox async {
    if (_playHistoryBox == null) {
      throw Exception('播放历史服务未初始化');
    }
    return _playHistoryBox!;
  }

  /// 读取播放历史记录
  Future<List<Song>> getPlayHistory() async {
    try {
      // 从 Hive Box 中获取播放历史数据
      final historyData = _playHistoryBox?.values.toList() ?? [];
      return historyData;
    } catch (e) {
      // 发生错误时返回空列表
      return [];
    }
  }

  /// 保存播放历史
  Future<void> saveHistory(List<Song> history) async {
    try {
      final box = await _historyBox;

      // 限制历史记录数量
      final limitedHistory = history.length > _maxHistorySize
          ? history.sublist(0, _maxHistorySize)
          : history;

      // 清空现有数据
      await box.clear();

      // 保存新数据
      for (var i = 0; i < limitedHistory.length; i++) {
        await box.put(i.toString(), limitedHistory[i]);
      }
    } catch (e) {
      // 如果保存失败，忽略错误
      if (kDebugMode) {
        print('保存播放历史失败: $e');
      }
    }
  }

  /// 添加歌曲到播放历史
  Future<void> addSongToHistory(Song song) async {
    try {
      // 读取现有历史
      final history = await getPlayHistory();

      // 检查歌曲是否已经在历史记录中
      final existingIndex = history.indexWhere((s) => s.id == song.id);
      if (existingIndex != -1) {
        // 如果存在，将其移到列表开头
        history.removeAt(existingIndex);
      }

      // 将歌曲添加到历史记录开头
      history.insert(0, song);

      // 保存更新后的历史
      await saveHistory(history);
    } catch (e) {
      // 如果添加失败，忽略错误
      if (kDebugMode) {
        print('添加歌曲到播放历史失败: $e');
      }
    }
  }

  /// 清空播放历史
  Future<void> clearHistory() async {
    try {
      final box = await _historyBox;

      // 清空历史记录
      await box.clear();
    } catch (e) {
      // 如果清空失败，忽略错误
      if (kDebugMode) {
        print('清空播放历史失败: $e');
      }
    }
  }
}
