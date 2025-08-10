import 'package:tune/core/network/network_info.dart';

/// 桌面端网络检测
class NetworkInfoDesktop implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // 桌面端网络检测逻辑
    // TODO: 实现桌面端网络检测
    return true;
  }

  @override
  Future<bool> get isWiFi async {
    // 桌面端WiFi检测逻辑
    // TODO: 实现桌面端WiFi检测
    return false;
  }
}