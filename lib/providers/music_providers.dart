import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/data/services/impl/platform_music_service.dart';

// 服务提供者
final platformMusicServiceProvider = Provider((ref) {
  return PlatformMusicService();
});

// 仓库提供提供者
final musicRepositoryProvider = Provider((ref) {
  final service = ref.watch(platformMusicServiceProvider);
  return MusicRepository(musicService: service);
});