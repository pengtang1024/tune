import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';

class LibraryState {
  final bool isGridView;
  final String searchQuery;
  final int selectedMenuItemIndex;
  final List<Song> songs;
  final bool isLoading;
  final String? errorMessage;

  LibraryState({
    required this.isGridView,
    required this.searchQuery,
    required this.selectedMenuItemIndex,
    required this.songs,
    required this.isLoading,
    this.errorMessage,
  });

  LibraryState copyWith({
    bool? isGridView,
    String? searchQuery,
    int? selectedMenuItemIndex,
    List<Song>? songs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LibraryState(
      isGridView: isGridView ?? this.isGridView,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMenuItemIndex: selectedMenuItemIndex ?? this.selectedMenuItemIndex,
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static LibraryState initial() {
    return LibraryState(
      isGridView: false,
      searchQuery: '',
      selectedMenuItemIndex: 0,
      songs: [],
      isLoading: false,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier() : super(LibraryState.initial());

  void toggleGridView() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSelectedMenuItemIndex(int index) {
    state = state.copyWith(selectedMenuItemIndex: index);
  }
  
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
  
  void setSongs(List<Song> songs) {
    state = state.copyWith(songs: songs, isLoading: false);
  }
  
  void setError(String error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }
}