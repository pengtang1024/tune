import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/data/services/impl/platform_music_service.dart';
import 'package:tune/ui/home/controllers/home_controller.dart';
import 'package:tune/ui/home/states/home_state.dart';
import 'package:tune/ui/home/states/home_state_notifier.dart';

/// HomeController提供者
final homeControllerProvider = Provider<HomeController>((ref) {
  final service = PlatformMusicService();
  final repository = MusicRepository(musicService: service);
  return HomeController(musicRepository: repository);
});

/// HomeStateNotifier提供者
final homeStateNotifierProvider =
    StateNotifierProvider<HomeStateNotifier, HomeState>((ref) {
  final controller = ref.watch(homeControllerProvider);
  return HomeStateNotifier(homeController: controller);
});
