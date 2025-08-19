import 'package:logger/logger.dart';
import 'package:tune/utils/logger_config.dart';

class Log {
  static final Logger _logger = Logger(
    printer: SingleLinePrinter(),
    // 可选：控制日志输出级别（如只输出 info 及以上级别）
    level: Level.info,
  );

  static void debug(String message) {
    // In a real app, you might want to use a proper logging package
    if (const bool.fromEnvironment('DEBUG')) {
      _logger.d('[DEBUG] $message');
    }
  }

  static void info(String message) {
    _logger.i('[INFO] $message');
  }

  static void error(String message, [StackTrace? stackTrace]) {
    _logger.e('[ERROR] $message', stackTrace: stackTrace);
  }

  static void errorWithStack(String message) {
    _logger.e('[ERROR] $message');
  }
}
