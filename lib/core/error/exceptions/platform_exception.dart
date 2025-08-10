import 'package:tune/core/error/exceptions/app_exception.dart';

/// 平台适配异常类
class PlatformException extends AppException {
  /// 平台信息
  final String platform;

  /// 构造函数
  PlatformException({
    required String message,
    required this.platform,
    String code = 'platform_error',
  }) : super(message: message, code: code);

  @override
  String toString() {
    return 'PlatformException: $message (code: $code, platform: $platform)';
  }
}