import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/utils/logger.dart';

/// 播放器状态管理器
class PlayerStateNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  late final AudioPlayerService _audioPlayerService;
  StreamSubscription? _positionSubscription;
  List<Song> _playlist = [];
  int _currentIndex = -1;

  PlayerStateNotifier(this._ref) : super(PlayerState.initial()) {
    _audioPlayerService = _ref.read(audioPlayerServiceProvider);
    _initializePlayer();
  }

  /// 初始化播放器
  void _initializePlayer() {
    // 实时更新播放位置
    _positionSubscription = Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
      try {
        if (state.currentSong != null) {
          final isPlaying = _audioPlayerService.isPlaying;
          final position = _audioPlayerService.currentPosition;
          final duration = _audioPlayerService.duration;
          
          // 只有当状态发生变化时才更新
          if (state.isPlaying != isPlaying || 
              state.position != position || 
              state.duration != duration) {
            state = state.copyWith(
              isPlaying: isPlaying,
              position: position,
              duration: duration,
            );
          }
        }
      } catch (e) {
        Log.error('更新播放位置时出错: $e');
      }
    });
  }

  /// 设置播放列表
  void setPlaylist(List<Song> playlist, int initialIndex) {
    _playlist = playlist;
    _currentIndex = initialIndex;
  }

  /// 播放歌曲
  Future<void> playSong(Song song) async {
    try {
      // 更新状态为加载中
      state = PlayerState.loading(song);

      // 播放歌曲
      await _audioPlayerService.play(song);
      
      // 更新状态为播放中
      state = PlayerState.playing(
        song,
        _audioPlayerService.currentPosition,
        _audioPlayerService.duration,
      ).copyWith(playMode: state.playMode);
    } catch (e) {
      Log.error('播放歌曲失败: $e');
      // 播放出错，更新状态为错误
      state = PlayerState.error('播放歌曲失败: $e');
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    try {
      if (state.isPlaying && state.currentSong != null) {
        await _audioPlayerService.pause();
        state = state.copyWith(isPlaying: false);
      }
    } catch (e) {
      Log.error('暂停播放失败: $e');
    }
  }

  /// 继续播放
  Future<void> play() async {
    try {
      if (!state.isPlaying && state.currentSong != null) {
        await _audioPlayerService.resume();
        state = state.copyWith(isPlaying: true);
      }
    } catch (e) {
      Log.error('继续播放失败: $e');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayerService.stop();
      state = PlayerState.initial();
    } catch (e) {
      Log.error('停止播放失败: $e');
    }
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    try {
      if (state.currentSong != null) {
        await _audioPlayerService.seekTo(position);
        state = state.copyWith(position: position);
      }
    } catch (e) {
      Log.error('跳转到指定位置失败: $e');
    }
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayerService.setVolume(volume);
      state = state.copyWith(volume: volume);
    } catch (e) {
      Log.error('设置音量失败: $e');
    }
  }

  /// 切换播放模式
  void togglePlayMode() {
    final nextMode = PlayMode.values[(state.playMode.index + 1) % PlayMode.values.length];
    state = state.copyWith(playMode: nextMode);
  }

  /// 播放下一首
  void next() {
    if (_playlist.isEmpty) return;
    
    switch (state.playMode) {
      case PlayMode.sequential:
        _currentIndex = (_currentIndex + 1) % _playlist.length;
        break;
      case PlayMode.repeatOne:
        // 保持当前索引不变
        break;
      case PlayMode.shuffle:
        _currentIndex = Random().nextInt(_playlist.length);
        break;
    }
    
    playSong(_playlist[_currentIndex]);
  }

  /// 播放上一首
  void previous() {
    if (_playlist.isEmpty) return;
    
    switch (state.playMode) {
      case PlayMode.sequential:
        _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        break;
      case PlayMode.repeatOne:
        // 保持当前索引不变
        break;
      case PlayMode.shuffle:
        _currentIndex = Random().nextInt(_playlist.length);
        break;
    }
    
    playSong(_playlist[_currentIndex]);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}