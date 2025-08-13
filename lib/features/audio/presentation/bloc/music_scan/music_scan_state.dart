import 'package:tune/domain/entities/song.dart';

/// 音乐扫描状态基类
abstract class MusicScanState {}

/// 初始状态
class MusicScanInitial extends MusicScanState {}

/// 加载状态
class MusicScanLoading extends MusicScanState {}

/// 扫描进行中状态
class MusicScanInProgress extends MusicScanState {
  final int progress;
  final String message;

  MusicScanInProgress({required this.progress, required this.message});
}

/// 扫描完成状态
class MusicScanCompleted extends MusicScanState {
  final List<Song> songs;
  final String message;

  MusicScanCompleted({required this.songs, required this.message});
}

/// 扫描错误状态
class MusicScanError extends MusicScanState {
  final String message;

  MusicScanError({required this.message});
}

/// 扫描取消状态
class MusicScanCancelled extends MusicScanState {}