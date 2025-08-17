import 'package:tune/domain/models/song.dart';

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