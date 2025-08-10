import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tune/core/network/network_info.dart';

/// 移动端网络检测（Connectivity_plus）
class NetworkInfoMobile implements NetworkInfo {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Future<bool> get isWiFi async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.wifi;
  }
}