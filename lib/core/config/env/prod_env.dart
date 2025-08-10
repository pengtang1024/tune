import 'package:tune/core/config/env/env.dart';

/// 生产环境配置
class ProdEnv implements Env {
  @override
  String get apiUrl => 'https://api.example.com';

  @override
  int get timeout => 15000;

  @override
  bool get isDebug => false;
}