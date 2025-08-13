/// 全局常量定义
class AppConstants {
  /// 应用版本号
  static const String version = '1.0.0';

  /// 存储键前缀
  static const String storageKeyPrefix = 'tune_';

  /// 默认分页大小
  static const int defaultPageSize = 20;

  /// 最大重试次数
  static const int maxRetryCount = 3;

  // 搜索历史相关常量
  static const String searchHistoryKey = 'search_history';
  static const int maxSearchHistoryCount = 20;
}