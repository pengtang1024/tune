/// 网络状态检测抽象接口
abstract class NetworkInfo {
  /// 检查是否有网络连接
  Future<bool> get isConnected;

  /// 检查是否为WiFi连接
  Future<bool> get isWiFi;
}