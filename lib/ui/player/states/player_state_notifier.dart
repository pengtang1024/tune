import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/services/play_mode_service.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/states/play_mode.dart';

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
    _positionSubscription = Stream.periodic(const Duration(milliseconds: 60)).listen((_) {
      if (state.currentSong != null && _audioPlayerService.isPlaying) {
        state = state.copyWith(
          position: _audioPlayerService.currentPosition,
          duration: _audioPlayerService.duration,
          isPlaying: _audioPlayerService.isPlaying,
        );
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
      // 播放出错，更新状态为错误
      state = PlayerState.error('播放歌曲失败: $e');
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    if (state.isPlaying && state.currentSong != null) {
      await _audioPlayerService.pause();
      state = state.copyWith(isPlaying: false);
    }
  }

  /// 继续播放
  Future<void> play() async {
    if (!state.isPlaying && state.currentSong != null) {
      await _audioPlayerService.resume();
      state = state.copyWith(isPlaying: true);
    }
  }

  /// 停止播放
  Future<void> stop() async {
    await _audioPlayerService.stop();
    state = PlayerState.initial();
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    if (state.currentSong != null) {
      await _audioPlayerService.seekTo(position);
      state = state.copyWith(position: position);
    }
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    await _audioPlayerService.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  /// 切换播放模式
  void togglePlayMode() {
    final nextMode = PlayModeService.getNextPlayMode(state.playMode);
    state = state.copyWith(playMode: nextMode);
  }

  /// 获取当前播放模式
  PlayMode get playMode => state.playMode;

  /// 播放下一首
  void skipToNext() {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    
    // 计算下一首歌曲的索引
    final nextIndex = PlayModeService.getNextIndex(_currentIndex, _playlist.length, state.playMode);
    if (nextIndex >= 0) {
      _currentIndex = nextIndex;
      playSong(_playlist[_currentIndex]);
    }
  }

  /// 播放上一首
  void skipToPrevious() {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    
    // 如果当前播放位置超过3秒，则回到开头而不是播放上一首
    if (state.position.inSeconds > 3) {
      seekTo(Duration.zero);
      return;
    }
    
    // 计算上一首歌曲的索引
    final previousIndex = PlayModeService.getPreviousIndex(_currentIndex, _playlist.length, state.playMode);
    if (previousIndex >= 0) {
      _currentIndex = previousIndex;
      playSong(_playlist[_currentIndex]);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _audioPlayerService.dispose();
    super.dispose();
  }
}