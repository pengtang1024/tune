/// 日期工具类
class DateUtils {
  /// 格式化时间戳为人类可读的格式
  static String formatTimestamp(int timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化秒数为分钟:秒钟格式
  static String formatSeconds(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 获取两个日期之间的天数差
  static int daysBetween(DateTime from, DateTime to) {
    final DateTime fromUTC = DateTime.utc(from.year, from.month, from.day);
    final DateTime toUTC = DateTime.utc(to.year, to.month, to.day);
    return (toUTC.difference(fromUTC).inHours / 24).round();
  }
}