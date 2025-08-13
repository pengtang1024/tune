part of 'music_library_bloc.dart';

abstract class MusicLibraryEvent {}

class LoadMusicLibrary extends MusicLibraryEvent {}

class SearchSongsEvent extends MusicLibraryEvent {
  final String query;

  SearchSongsEvent(this.query);
}

class SortSongs extends MusicLibraryEvent {
  final String sortBy;

  SortSongs(this.sortBy);
}

class GroupSongs extends MusicLibraryEvent {
  final String groupBy;

  GroupSongs(this.groupBy);
}

class RefreshLibrary extends MusicLibraryEvent {}