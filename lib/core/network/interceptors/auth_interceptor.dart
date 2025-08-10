import 'package:dio/dio.dart';

/// 认证拦截器
class AuthInterceptor extends Interceptor {
  /// 用户令牌获取函数
  final Future<String?> Function() getToken;

  /// 构造函数
  AuthInterceptor({required this.getToken});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 获取用户令牌
    final token = await getToken();

    // 如果有令牌，则添加到请求头中
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }
}