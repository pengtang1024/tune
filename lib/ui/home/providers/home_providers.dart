import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/data/services/impl/platform_music_service.dart';
import 'package:tune/ui/home/view_model/home_view_model.dart';

/// 主页视图模型提供者
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeViewState>((ref) {
  // 重新创建依赖项而不是从其他providers文件中导入
  final service = PlatformMusicService();
  final repository = MusicRepository(musicService: service);
  return HomeViewModel(musicRepository: repository);
});
