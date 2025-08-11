import 'package:equatable/equatable.dart';
import 'package:tune/domain/entities/song.dart';

/// 搜索状态基类
abstract class SearchState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 初始搜索状态
class SearchInitial extends SearchState {}

/// 搜索加载状态
class SearchLoadingState extends SearchState {}

/// 搜索完成状态
class SearchCompletedState extends SearchState {
  /// 搜索结果歌曲列表
  final List<Song> songs;

  SearchCompletedState({required this.songs});

  @override
  List<Object?> get props => [songs];
}

/// 搜索错误状态
class SearchErrorState extends SearchState {
  /// 错误信息
  final String message;

  SearchErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

/// 搜索清除状态
class SearchClearedState extends SearchState {}