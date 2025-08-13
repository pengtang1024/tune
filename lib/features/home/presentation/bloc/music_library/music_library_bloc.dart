import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/domain/usecases/search_songs.dart';

part 'music_library_event.dart';
part 'music_library_state.dart';

class MusicLibraryBloc extends Bloc<MusicLibraryEvent, MusicLibraryState> {
  final GetAllSongs _getAllSongs;
  final SearchSongs _searchSongs;

  MusicLibraryBloc({
    required GetAllSongs getAllSongs,
    required SearchSongs searchSongs,
  })  : _getAllSongs = getAllSongs,
        _searchSongs = searchSongs,
        super(MusicLibraryInitial()) {
    on<LoadMusicLibrary>(_onLoadMusicLibrary);
    on<SearchSongsEvent>(_onSearchSongs);
    on<SortSongs>(_onSortSongs);
    on<GroupSongs>(_onGroupSongs);
    on<RefreshLibrary>(_onRefreshLibrary);
  }

  Future<void> _onLoadMusicLibrary(
    LoadMusicLibrary event,
    Emitter<MusicLibraryState> emit,
  ) async {
    emit(MusicLibraryLoading());
    try {
      final songs = await _getAllSongs();
      emit(MusicLibraryLoaded(songs: songs));
    } catch (e) {
      emit(MusicLibraryError('Failed to load music library: $e'));
    }
  }

  Future<void> _onSearchSongs(
    SearchSongsEvent event,
    Emitter<MusicLibraryState> emit,
  ) async {
    if (event.query.isEmpty) {
      // 如果搜索查询为空，加载所有歌曲
      add(LoadMusicLibrary());
      return;
    }

    emit(MusicLibraryLoading());
    try {
      final songs = await _searchSongs(event.query);
      emit(MusicLibrarySearchResult(songs: songs, query: event.query));
    } catch (e) {
      emit(MusicLibraryError('Failed to search songs: $e'));
    }
  }

  Future<void> _onSortSongs(
    SortSongs event,
    Emitter<MusicLibraryState> emit,
  ) async {
    // 这里应该根据当前状态进行排序
    if (state is MusicLibraryLoaded) {
      final currentState = state as MusicLibraryLoaded;
      final sortedSongs = List<Song>.from(currentState.songs);

      switch (event.sortBy) {
        case 'title':
          sortedSongs.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'artist':
          sortedSongs.sort((a, b) => a.artist.compareTo(b.artist));
          break;
        case 'album':
          sortedSongs.sort((a, b) => a.album.compareTo(b.album));
          break;
        case 'dateAdded':
          sortedSongs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
          break;
        case 'duration':
          sortedSongs.sort((a, b) => a.duration.compareTo(b.duration));
          break;
        default:
          sortedSongs.sort((a, b) => a.title.compareTo(b.title));
      }

      emit(MusicLibraryLoaded(
        songs: sortedSongs,
        groupedSongs: currentState.groupedSongs,
        groupBy: currentState.groupBy,
      ));
    } else if (state is MusicLibrarySearchResult) {
      final currentState = state as MusicLibrarySearchResult;
      final sortedSongs = List<Song>.from(currentState.songs);

      switch (event.sortBy) {
        case 'title':
          sortedSongs.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'artist':
          sortedSongs.sort((a, b) => a.artist.compareTo(b.artist));
          break;
        case 'album':
          sortedSongs.sort((a, b) => a.album.compareTo(b.album));
          break;
        case 'dateAdded':
          sortedSongs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
          break;
        case 'duration':
          sortedSongs.sort((a, b) => a.duration.compareTo(b.duration));
          break;
        default:
          sortedSongs.sort((a, b) => a.title.compareTo(b.title));
      }

      emit(MusicLibrarySearchResult(
        songs: sortedSongs,
        query: currentState.query,
        groupedSongs: currentState.groupedSongs,
        groupBy: currentState.groupBy,
      ));
    }
  }

  Future<void> _onGroupSongs(
    GroupSongs event,
    Emitter<MusicLibraryState> emit,
  ) async {
    if (state is MusicLibraryLoaded) {
      final currentState = state as MusicLibraryLoaded;
      final groupedSongs = <String, List<Song>>{};

      switch (event.groupBy) {
        case 'artist':
          for (final song in currentState.songs) {
            if (groupedSongs.containsKey(song.artist)) {
              groupedSongs[song.artist]!.add(song);
            } else {
              groupedSongs[song.artist] = [song];
            }
          }
          break;
        case 'album':
          for (final song in currentState.songs) {
            if (groupedSongs.containsKey(song.album)) {
              groupedSongs[song.album]!.add(song);
            } else {
              groupedSongs[song.album] = [song];
            }
          }
          break;
        case 'genre':
          for (final song in currentState.songs) {
            if (groupedSongs.containsKey(song.genre)) {
              groupedSongs[song.genre]!.add(song);
            } else {
              groupedSongs[song.genre] = [song];
            }
          }
          break;
        default:
          // 不分组，直接返回原列表
          emit(MusicLibraryLoaded(songs: currentState.songs));
          return;
      }

      emit(MusicLibraryLoaded(
        songs: currentState.songs,
        groupedSongs: groupedSongs,
        groupBy: event.groupBy,
      ));
    } else if (state is MusicLibrarySearchResult) {
      final currentState = state as MusicLibrarySearchResult;
      final groupedSongs = <String, List<Song>>{};

      switch (event.groupBy) {
        case 'artist':
          for (final song in currentState.songs) {
            if (groupedSongs.containsKey(song.artist)) {
              groupedSongs[song.artist]!.add(song);
            } else {
              groupedSongs[song.artist] = [song];
            }
          }
          break;
        case 'album':
          for (final song in currentState.songs) {
            if (groupedSongs.containsKey(song.album)) {
              groupedSongs[song.album]!.add(song);
            } else {
              groupedSongs[song.album] = [song];
            }
          }
          break;
        case 'genre':
          for (final song in currentState.songs) {
            if (groupedSongs.containsKey(song.genre)) {
              groupedSongs[song.genre]!.add(song);
            } else {
              groupedSongs[song.genre] = [song];
            }
          }
          break;
        default:
          // 不分组，直接返回原列表
          emit(MusicLibrarySearchResult(songs: currentState.songs, query: currentState.query));
          return;
      }

      emit(MusicLibrarySearchResult(
        songs: currentState.songs,
        query: currentState.query,
        groupedSongs: groupedSongs,
        groupBy: event.groupBy,
      ));
    }
  }
  
  Future<void> _onRefreshLibrary(
    RefreshLibrary event,
    Emitter<MusicLibraryState> emit,
  ) async {
    add(LoadMusicLibrary());
  }
}