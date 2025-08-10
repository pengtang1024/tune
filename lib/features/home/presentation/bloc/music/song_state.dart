import 'package:equatable/equatable.dart';
import 'package:tune/domain/entities/song.dart';

/// 歌曲状态基类
abstract class SongState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 初始状态
class SongInitial extends SongState {}

/// 加载中状态
class SongLoading extends SongState {}

/// 加载完成状态
class SongLoaded extends SongState {
  /// 歌曲列表
  final List<Song> songs;

  /// 构造函数
  SongLoaded({required this.songs});

  @override
  List<Object?> get props => [songs];
}

/// 错误状态
class SongError extends SongState {
  /// 错误消息
  final String message;

  /// 构造函数
  SongError({required this.message});

  @override
  List<Object?> get props => [message];
}