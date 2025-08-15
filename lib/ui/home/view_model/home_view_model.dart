import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/menu_item.dart';

class HomeViewState {
  final bool isLoading;
  final List<Song> songs;
  final String errorMessage;
  final MenuItem? selectedMenuItem;

  HomeViewState({
    required this.isLoading,
    required this.songs,
    required this.errorMessage,
    required this.selectedMenuItem,
  });

  HomeViewState copyWith({
    bool? isLoading,
    List<Song>? songs,
    String? errorMessage,
    MenuItem? selectedMenuItem,
  }) {
    return HomeViewState(
      isLoading: isLoading ?? this.isLoading,
      songs: songs ?? this.songs,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedMenuItem: selectedMenuItem ?? this.selectedMenuItem,
    );
  }

  static HomeViewState initial() {
    return HomeViewState(
      isLoading: false,
      songs: [],
      errorMessage: '',
      selectedMenuItem: null,
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

  void setSelectedMenuItem(MenuItem? item) {
    state = state.copyWith(selectedMenuItem: item);
  }
  
  void clearSelectedMenuItem() {
    state = state.copyWith(selectedMenuItem: null);
  }
}