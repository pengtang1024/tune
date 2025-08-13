part of 'music_library_bloc.dart';

abstract class MusicLibraryState {}

class MusicLibraryInitial extends MusicLibraryState {}

class MusicLibraryLoading extends MusicLibraryState {}

class MusicLibraryLoaded extends MusicLibraryState {
  final List<Song> songs;
  final Map<String, List<Song>>? groupedSongs;
  final String? groupBy;

  MusicLibraryLoaded({
    required this.songs,
    this.groupedSongs,
    this.groupBy,
  });
}

class MusicLibraryError extends MusicLibraryState {
  final String message;

  MusicLibraryError(this.message);
}

class MusicLibrarySearchResult extends MusicLibraryState {
  final List<Song> songs;
  final String query;
  final Map<String, List<Song>>? groupedSongs;
  final String? groupBy;

  MusicLibrarySearchResult({
    required this.songs,
    required this.query,
    this.groupedSongs,
    this.groupBy,
  });
}