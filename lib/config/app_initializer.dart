import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/router/app_router.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/providers/music_providers.dart';
import 'package:tune/providers/persistence_providers.dart';

/// 应用初始化器
class AppInitializer {
  /// 初始化应用所需的所有服务
  static Future<void> init(Ref ref) async {
    // 初始化持久化服务
    await ref.read(sharedPreferencesServiceProvider);
    await ref.read(routerProvider);

    // 延迟一小段时间以确保服务正确初始化
    await Future.delayed(const Duration(milliseconds: 10));

    await ref.read(menuStateProvider);
    // 初始化音乐服务
    await ref.read(musicRepositoryProvider);
    await ref.read(platformMusicServiceProvider);

    // 可以在这里初始化其他服务
  }
}
