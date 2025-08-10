/// API客户端抽象接口
abstract class ApiClient {
  /// 发起GET请求
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? headers});

  /// 发起POST请求
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? headers,
  });

  /// 发起PUT请求
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? headers,
  });

  /// 发起DELETE请求
  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? headers});
}