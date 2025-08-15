import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/music_providers.dart';
import 'package:tune/providers/persistence_providers.dart';

/// 应用初始化器
class AppInitializer {
  /// 初始化应用所需的所有服务
  static Future<void> init(Ref ref) async {
    // 初始化持久化服务
    ref.read(sharedPreferencesServiceProvider);
    // 初始化音乐服务
    ref.read(musicRepositoryProvider);
    ref.read(platformMusicServiceProvider);

    // 可以在这里初始化其他服务
  }
}
