import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/features/home/domain/usecases/get_recently_played_songs.dart';
import 'package:tune/features/home/domain/usecases/get_recommended_songs.dart';
import 'package:tune/features/home/presentation/bloc/home_event.dart';
import 'package:tune/features/home/presentation/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetRecentlyPlayedSongs _getRecentlyPlayedSongs;
  final GetRecommendedSongs _getRecommendedSongs;

  HomeBloc({
    required GetRecentlyPlayedSongs getRecentlyPlayedSongs,
    required GetRecommendedSongs getRecommendedSongs,
  })  : _getRecentlyPlayedSongs = getRecentlyPlayedSongs,
        _getRecommendedSongs = getRecommendedSongs,
        super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<SaveRecentlyPlayedSong>(_onSaveRecentlyPlayedSong);
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final recentlyPlayedSongs = await _getRecentlyPlayedSongs();
      final recommendedSongs = await _getRecommendedSongs();
      emit(HomeLoaded(
        recentlyPlayedSongs: recentlyPlayedSongs,
        recommendedSongs: recommendedSongs,
      ));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _onSaveRecentlyPlayedSong(
      SaveRecentlyPlayedSong event, Emitter<HomeState> emit) async {
    // TODO: 实现保存最近播放歌曲的逻辑
    // 这里可能需要更新状态或者调用相关用例
  }
}
