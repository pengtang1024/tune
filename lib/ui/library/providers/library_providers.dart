import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/music_providers.dart';
import 'package:tune/ui/library/controllers/library_controller.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/states/library_state_notifier.dart';
import 'package:tune/ui/library/states/search_state.dart';
import 'package:tune/ui/library/states/search_state_notifier.dart';

// Library状态管理器提供者
final libraryStateNotifierProvider =
    StateNotifierProvider<LibraryStateNotifier, LibraryState>((ref) {
  return LibraryStateNotifier();
});

// Library控制器提供者
final libraryControllerProvider = Provider<LibraryController>((ref) {
  final repository = ref.watch(musicRepositoryProvider);
  return LibraryController(musicRepository: repository);
});

// 所有歌曲提供者
final songsProvider = FutureProvider<List<Song>>((ref) async {
  final controller = ref.watch(libraryControllerProvider);
  return await controller.getAllSongs();
});

// 搜索状态管理器提供者
final searchStateNotifierProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  final repository = ref.watch(musicRepositoryProvider);
  return SearchStateNotifier(musicRepository: repository);
});
