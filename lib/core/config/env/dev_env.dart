import 'package:tune/core/config/env/env.dart';

/// 开发环境配置
class DevEnv implements Env {
  @override
  String get apiUrl => 'https://dev-api.example.com';

  @override
  int get timeout => 30000;

  @override
  bool get isDebug => true;
}