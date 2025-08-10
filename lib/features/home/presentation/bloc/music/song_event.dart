import 'package:equatable/equatable.dart';

/// 歌曲事件基类
abstract class SongEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 加载歌曲事件
class LoadSongs extends SongEvent {}

/// 搜索歌曲事件
class SearchSongsEvent extends SongEvent {
  /// 搜索关键词
  final String query;

  /// 构造函数
  SearchSongsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}