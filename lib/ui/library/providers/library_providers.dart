import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/music_providers.dart';
import 'package:tune/ui/library/view_model/library_view_model.dart';
import 'package:tune/ui/library/view_model/search_view_model.dart';

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});

final songsProvider = FutureProvider<List<Song>>((ref) async {
  try {
    final repository = ref.watch(musicRepositoryProvider);
    return await repository.getAllSongs();
  } catch (e) {
    // 返回空列表而不是抛出错误，确保UI可以正常显示
    return [];
  }
});

final searchSongsProvider = FutureProvider.family<List<Song>, String>((ref, query) async {
  try {
    if (query.trim().isEmpty) {
      return [];
    }
    
    final repository = ref.watch(musicRepositoryProvider);
    return await repository.searchSongs(query);
  } catch (e) {
    // 返回空列表而不是抛出错误，确保UI可以正常显示
    return [];
  }
});

// 搜索视图模型提供者
final searchViewModelProvider = StateNotifierProvider<SearchViewModel, SearchState>((ref) {
  final repository = ref.watch(musicRepositoryProvider);
  return SearchViewModel(musicRepository: repository);
});