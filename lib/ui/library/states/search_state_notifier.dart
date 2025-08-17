import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/ui/library/states/search_state.dart';
import 'package:tune/utils/logger.dart';

class SearchStateNotifier extends StateNotifier<SearchState> {
  final MusicRepository _musicRepository;

  SearchStateNotifier({required MusicRepository musicRepository})
      : _musicRepository = musicRepository,
        super(SearchState.initial());

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  Future<void> searchSongs(String query) async {
    Log.info('SearchStateNotifier: Searching for songs with query: $query');
    
    // 如果查询为空，返回所有歌曲
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: query,
        songs: [],
        isLoading: false,
        errorMessage: '',
      );
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
      errorMessage: '',
    );

    try {
      final songs = await _musicRepository.searchSongs(query);
      Log.info('SearchStateNotifier: Found ${songs.length} songs');
      state = state.copyWith(
        isLoading: false,
        songs: songs,
        errorMessage: '',
      );
    } catch (e) {
      Log.info('SearchStateNotifier: Error searching songs: $e');
      state = state.copyWith(
        isLoading: false,
        songs: [],
        errorMessage: e.toString(),
      );
    }
  }
}