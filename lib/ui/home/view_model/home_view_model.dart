import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/domain/models/song.dart';

class HomeViewState {
  final bool isLoading;
  final List<Song> songs;
  final String errorMessage;

  HomeViewState({
    required this.isLoading,
    required this.songs,
    required this.errorMessage,
  });

  HomeViewState copyWith({
    bool? isLoading,
    List<Song>? songs,
    String? errorMessage
  }) {
    return HomeViewState(
      isLoading: isLoading ?? this.isLoading,
      songs: songs ?? this.songs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static HomeViewState initial() {
    return HomeViewState(
      isLoading: false,
      songs: [],
      errorMessage: '',
    );
  }
}

class HomeViewModel extends StateNotifier<HomeViewState> {
  final MusicRepository _musicRepository;

  HomeViewModel({required MusicRepository musicRepository})
      : _musicRepository = musicRepository,
        super(HomeViewState.initial());

  Future<void> loadSongs() async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final songs = await _musicRepository.getAllSongs();
      state = state.copyWith(
        isLoading: false,
        songs: songs,
        errorMessage: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        songs: [],
        errorMessage: e.toString(),
      );
    }
  }
}
