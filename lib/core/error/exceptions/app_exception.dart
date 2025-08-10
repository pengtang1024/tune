/// 应用基础异常类
class AppException implements Exception {
  /// 异常消息
  final String message;

  /// 异常代码
  final String code;

  /// 构造函数
  AppException({
    required this.message,
    this.code = 'unknown',
  });

  @override
  String toString() {
    return 'AppException: $message (code: $code)';
  }
}