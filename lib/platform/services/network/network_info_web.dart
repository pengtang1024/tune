import 'package:tune/core/network/network_info.dart';

/// Web端网络检测（Navigator.connection）
class NetworkInfoWeb implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // Web端网络检测逻辑
    // TODO: 实现Web端网络检测
    return true;
  }

  @override
  Future<bool> get isWiFi async {
    // Web端WiFi检测逻辑
    // TODO: 实现Web端WiFi检测
    return false;
  }
}