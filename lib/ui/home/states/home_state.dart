import 'package:tune/domain/models/song.dart';

class HomeState {
  final bool isLoading;
  final List<Song> songs;
  final String errorMessage;

  HomeState({
    required this.isLoading,
    required this.songs,
    required this.errorMessage,
  });

  HomeState copyWith({
    bool? isLoading,
    List<Song>? songs,
    String? errorMessage
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      songs: songs ?? this.songs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static HomeState initial() {
    return HomeState(
      isLoading: false,
      songs: [],
      errorMessage: '',
    );
  }
}