import 'package:tune/core/error/exceptions/app_exception.dart';

/// 网络异常类
class NetworkException extends AppException {
  /// HTTP状态码
  final int? statusCode;

  /// 构造函数
  NetworkException({
    required String message,
    this.statusCode,
    String code = 'network_error',
  }) : super(message: message, code: code);

  @override
  String toString() {
    return 'NetworkException: $message (code: $code, status: $statusCode)';
  }
}