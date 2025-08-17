import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/states/player_state.dart';

/// 播放器状态管理器
class PlayerStateNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  late final AudioPlayerService _audioPlayerService;
  StreamSubscription? _positionSubscription;

  PlayerStateNotifier(this._ref) : super(PlayerState.initial()) {
    _audioPlayerService = _ref.read(audioPlayerServiceProvider);
    _initializePlayer();
  }

  /// 初始化播放器
  void _initializePlayer() {
    // 定期更新播放位置
    _positionSubscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (state.currentSong != null && _audioPlayerService.isPlaying) {
        state = state.copyWith(
          position: _audioPlayerService.currentPosition,
          duration: _audioPlayerService.duration,
          isPlaying: _audioPlayerService.isPlaying,
        );
      }
    });
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
      );
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

  /// 切换随机播放模式
  void toggleShuffleMode() {
    state = state.copyWith(isShuffleMode: !state.isShuffleMode);
  }

  /// 播放下一首
  void skipToNext() {
    // TODO: 实现播放下一首逻辑
  }

  /// 播放上一首
  void skipToPrevious() {
    // TODO: 实现播放上一首逻辑
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _audioPlayerService.dispose();
    super.dispose();
  }
}