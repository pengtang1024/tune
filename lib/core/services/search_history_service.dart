import 'dart:convert';
import 'package:tune/core/config/app_constants.dart';
import 'package:tune/core/storage/storage.dart';

/// 搜索历史服务
///
/// 负责管理搜索历史记录，包括添加、获取和清除历史记录
class SearchHistoryService {
  final Storage _storage;

  SearchHistoryService(this._storage);

  /// 添加搜索历史
  Future<void> addSearchHistory(String query) async {
    if (query.isEmpty) return;

    final history = await getSearchHistory();
    
    // 移除重复项
    history.removeWhere((item) => item == query);
    
    // 将新项添加到列表开头
    history.insert(0, query);
    
    // 限制历史记录数量
    if (history.length > AppConstants.maxSearchHistoryCount) {
      history.removeRange(
          AppConstants.maxSearchHistoryCount, history.length);
    }

    await _saveSearchHistory(history);
  }

  /// 获取搜索历史
  Future<List<String>> getSearchHistory() async {
    final historyString = await _storage.getString(
        AppConstants.searchHistoryKey, defaultValue: '[]');
    
    try {
      final List<dynamic> historyList = jsonDecode(historyString);
      return historyList.cast<String>();
    } catch (e) {
      // 如果解析失败，返回空列表并重置存储
      await _saveSearchHistory([]);
      return [];
    }
  }

  /// 清除搜索历史
  Future<void> clearSearchHistory() async {
    await _saveSearchHistory([]);
  }

  /// 保存搜索历史
  Future<void> _saveSearchHistory(List<String> history) async {
    final historyString = jsonEncode(history);
    await _storage.setString(AppConstants.searchHistoryKey, historyString);
  }
}

// 生成的代码需要执行: flutter pub run build_runner build