import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 日志拦截器
class LogInterceptor extends Interceptor {
  /// 是否为Web端
  final bool isWeb;

  /// 构造函数
  LogInterceptor({this.isWeb = false});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Web端屏蔽敏感信息
    if (isWeb) {
      // TODO: 屏蔽Web端敏感信息
    }

    if (kDebugMode) {
      print('--- HTTP Request ---');
      print('Method: ${options.method}');
      print('URL: ${options.uri}');
      print('Headers: ${options.headers}');
      print('Data: ${options.data}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      print('--- HTTP Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      print('--- HTTP Error ---');
      print('Error: ${err.message}');
      print('Error Type: ${err.type}');
    }

    super.onError(err, handler);
  }
}