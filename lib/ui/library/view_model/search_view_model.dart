import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

class SearchState {
  final bool isLoading;
  final List<Song> songs;
  final String query;
  final String errorMessage;

  SearchState({
    required this.isLoading,
    required this.songs,
    required this.query,
    required this.errorMessage,
  });

  SearchState copyWith({
    bool? isLoading,
    List<Song>? songs,
    String? query,
    String? errorMessage,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      songs: songs ?? this.songs,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static SearchState initial() {
    return SearchState(
      isLoading: false,
      songs: [],
      query: '',
      errorMessage: '',
    );
  }
}

class SearchViewModel extends StateNotifier<SearchState> {
  final MusicRepository _musicRepository;

  SearchViewModel({required MusicRepository musicRepository})
      : _musicRepository = musicRepository,
        super(SearchState.initial());

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  Future<void> searchSongs(String query) async {
    Log.info('SearchViewModel: Searching for songs with query: $query');
    
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
      Log.info('SearchViewModel: Found ${songs.length} songs');
      state = state.copyWith(
        isLoading: false,
        songs: songs,
        errorMessage: '',
      );
    } catch (e) {
      Log.info('SearchViewModel: Error searching songs: $e');
      state = state.copyWith(
        isLoading: false,
        songs: [],
        errorMessage: e.toString(),
      );
    }
  }
}