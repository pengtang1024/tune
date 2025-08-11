import 'package:equatable/equatable.dart';

/// 搜索事件基类
abstract class SearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 搜索歌曲事件
class SearchSongsEvent extends SearchEvent {
  /// 搜索关键词
  final String query;

  SearchSongsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// 清除搜索事件
class ClearSearchEvent extends SearchEvent {}