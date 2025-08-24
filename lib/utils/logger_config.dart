import 'package:logger/logger.dart';

// 自定义单行日志打印器
class SingleLinePrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    // 格式化时间（可选）
    final time = DateTime.now().toIso8601String().split('T')[1];

    // 日志级别缩写（如：V=Verbose, D=Debug, I=Info, W=Warn, E=Error）
    final level = _levelToAbbr(event.level);

    // 拼接单行日志：时间 + 级别 + 消息
    final line = '[$time] [$level] ${event.message}';

    // 返回单行列表（logger 要求返回 List<String>）
    return [line];
  }

  // 将日志级别转换为缩写
  String _levelToAbbr(Level level) {
    switch (level) {
      case Level.trace: return 'T';
      case Level.debug: return 'D';
      case Level.info: return 'I';
      case Level.warning: return 'W';
      case Level.error: return 'E';
      case Level.fatal: return 'FATAL';
      default: return '?';
    }
  }
}

// 初始化单行日志工具
final logger = Logger(
  printer: SingleLinePrinter(),
  // 可选：控制日志输出级别（如只输出 info 及以上级别）
  level: Level.trace,
);
