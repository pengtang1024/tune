import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:tune/domain/entities/song.dart';

/// 播放状态数据类
class PlaybackState {
  final PlayerState playerState;
  final Duration position;
  final Duration? duration;

  PlaybackState({
    required this.playerState,
    required this.position,
    this.duration,
  });
}

/// 媒体项数据类
class MediaItem {
  final String id;
  final String title;
  final String? artist;

  MediaItem({
    required this.id,
    required this.title,
    this.artist,
  });
}

/// 音频服务接口
abstract class IAudioService {
  /// 播放状态流
  Stream<PlayerState> get playerStateStream;

  /// 当前播放位置流
  Stream<Duration> get positionStream;

  /// 总时长流
  Stream<Duration?> get durationStream;

  /// 当前索引流
  Stream<int?> get currentIndexStream;

  /// 播放列表流
  Stream<SequenceState?> get sequenceStateStream;

  /// 组合流，包含播放状态、位置和时长
  Stream<PlaybackState> get playbackStateStream;

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs);

  /// 播放
  Future<void> play();

  /// 播放指定歌曲
  Future<void> playSong(Song song, List<Song> playlist);

  /// 暂停
  Future<void> pause();

  /// 停止
  Future<void> stop();

  /// 跳到指定位置
  Future<void> seek(Duration position);

  /// 跳到下一首
  Future<void> skipToNext();

  /// 跳到上一首
  Future<void> skipToPrevious();

  /// 设置音量
  Future<void> setVolume(double volume);

  /// 设置播放模式
  Future<void> setLoopMode(LoopMode loopMode);

  /// 设置随机播放模式
  Future<void> setShuffleMode(bool shuffle);

  /// 设置播放速度
  Future<void> setSpeed(double speed);

  /// 释放资源
  void dispose();
}
