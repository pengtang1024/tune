import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:tune/core/network/client/api_client.dart';

/// Dio客户端实现
class DioClient implements ApiClient {
  /// Dio实例
  final Dio _dio;

  /// 构造函数
  DioClient({
    required String baseUrl,
    required int timeout,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: Duration(milliseconds: timeout),
            receiveTimeout: Duration(milliseconds: timeout),
          ),
        );

  @override
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.get(
        endpoint,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } on DioException catch (e) {
      // TODO: 处理Dio异常
      log("DioClient get error: $e");
      rethrow;
    }
  }

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } on DioException catch (e) {
      // TODO: 处理Dio异常
      log("DioClient post error: $e");
      rethrow;
    }
  }

  @override
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } on DioException catch (e) {
      // TODO: 处理Dio异常
      log("DioClient put error: $e");
      rethrow;
    }
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } on DioException catch (e) {
      // TODO: 处理Dio异常
      log("DioClient delete error: $e");
      rethrow;
    }
  }
}
