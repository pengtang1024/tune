import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/features/home/presentation/bloc/music/song_event.dart';
import 'package:tune/features/home/presentation/bloc/music/song_state.dart';

/// 歌曲Bloc
class SongBloc extends Bloc<SongEvent, SongState> {
  /// 获取所有歌曲用例
  final GetAllSongs getAllSongs;

  /// 搜索歌曲用例
  final SearchSongs searchSongs;

  /// 构造函数
  SongBloc({
    required this.getAllSongs,
    required this.searchSongs,
  }) : super(SongInitial()) {
    on<LoadSongs>(_onLoadSongs);
    on<SearchSongsEvent>(_onSearchSongs);
  }

  /// 处理加载歌曲事件
  Future<void> _onLoadSongs(
    LoadSongs event,
    Emitter<SongState> emit,
  ) async {
    emit(SongLoading());
    try {
      final songs = await getAllSongs();
      emit(SongLoaded(songs: songs));
    } catch (e) {
      emit(SongError(message: e.toString()));
    }
  }

  /// 处理搜索歌曲事件
  Future<void> _onSearchSongs(
    SearchSongsEvent event,
    Emitter<SongState> emit,
  ) async {
    emit(SongLoading());
    try {
      final songs = await searchSongs(event.query);
      emit(SongLoaded(songs: songs));
    } catch (e) {
      emit(SongError(message: e.toString()));
    }
  }
}
