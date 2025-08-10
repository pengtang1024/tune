/// 环境抽象类
///
/// 定义应用环境配置的接口
abstract class Env {
  /// API基础URL
  String get apiUrl;

  /// 请求超时时间（毫秒）
  int get timeout;

  /// 是否为调试模式
  bool get isDebug;
}