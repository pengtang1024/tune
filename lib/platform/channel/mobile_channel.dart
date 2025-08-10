import 'package:flutter/services.dart';

/// 移动端MethodChannel（调用原生API）
class MobileChannel {
  /// Channel名称
  static const String _channelName = 'tune/mobile';

  /// MethodChannel实例
  static const MethodChannel _channel = MethodChannel(_channelName);

  /// 调用原生方法
  static Future<dynamic> invokeMethod(String method, [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod(method, arguments);
    } on PlatformException catch (e) {
      // 处理平台异常
      print('Platform exception: ${e.message}');
      rethrow;
    }
  }
}