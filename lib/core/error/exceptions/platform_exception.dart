import 'package:tune/core/error/exceptions/app_exception.dart';

/// 平台适配异常类
class PlatformException extends AppException {
  /// 平台信息
  final String platform;

  /// 构造函数
  PlatformException({
    required super.message,
    required this.platform,
    super.code = 'platform_error',
  });

  @override
  String toString() {
    return 'PlatformException: $message (code: $code, platform: $platform)';
  }
}
