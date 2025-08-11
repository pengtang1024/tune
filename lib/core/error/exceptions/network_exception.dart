import 'package:tune/core/error/exceptions/app_exception.dart';

/// 网络异常类
class NetworkException extends AppException {
  /// HTTP状态码
  final int? statusCode;

  /// 构造函数
  NetworkException({
    required super.message,
    this.statusCode,
    super.code = 'network_error',
  });

  @override
  String toString() {
    return 'NetworkException: $message (code: $code, status: $statusCode)';
  }
}
