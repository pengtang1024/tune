import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/bloc/search/search_event.dart';
import 'package:tune/core/bloc/search/search_state.dart';
import 'package:tune/domain/usecases/search_songs.dart';

/// 搜索Bloc类
///
/// 负责管理应用程序的搜索状态，处理搜索事件
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  /// 搜索歌曲用例
  final SearchSongs _searchSongs;

  /// 创建搜索Bloc实例
  ///
  /// 初始化Bloc，设置初始状态为SearchInitial，并注册事件处理器。
  SearchBloc({required SearchSongs searchSongs})
      : _searchSongs = searchSongs,
        super(SearchInitial()) {
    // 注册搜索事件的处理器
    on<SearchSongsEvent>(_onSearchSongs);
    on<ClearSearchEvent>(_onClearSearch);
  }

  /// 处理搜索歌曲事件
  ///
  /// 当用户在搜索页面输入搜索词时，会触发此事件处理器。
  ///
  /// [event] 搜索歌曲事件，包含搜索关键词
  /// [emit] 状态发射器，用于发出新的状态
  Future<void> _onSearchSongs(
      SearchSongsEvent event, Emitter<SearchState> emit) async {
    // 如果搜索关键词为空，清空搜索结果
    if (event.query.isEmpty) {
      emit(SearchClearedState());
      return;
    }

    try {
      // 发出搜索加载状态
      emit(SearchLoadingState());
      
      // 执行搜索
      final songs = await _searchSongs(event.query);
      
      // 发出搜索完成状态
      emit(SearchCompletedState(songs: songs));
    } catch (e) {
      // 发出搜索错误状态
      emit(SearchErrorState(message: e.toString()));
    }
  }

  /// 处理清除搜索事件
  ///
  /// 当用户清除搜索内容时，会触发此事件处理器。
  ///
  /// [event] 清除搜索事件
  /// [emit] 状态发射器，用于发出新的状态
  Future<void> _onClearSearch(
      ClearSearchEvent event, Emitter<SearchState> emit) async {
    emit(SearchClearedState());
  }
}