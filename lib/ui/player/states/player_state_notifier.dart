import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/player/extensions/player_control_extension.dart';
import 'package:tune/ui/player/extensions/resource_management_extension.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/utils/logger.dart';

/// 播放器状态管理器 - 简化版本
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
    try {
      _positionSubscription = _audioPlayerService.createPositionStream()
          .listen(_handlePositionUpdate, onError: _handlePositionError);
    } catch (e, stackTrace) {
      Log.error('播放器初始化失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 处理位置更新
  void _handlePositionUpdate(Duration position) {
    if (state.currentSong != null) {
      final stateInfo = _audioPlayerService.getPlayerStateInfo();
      
      if (state.isLoading && stateInfo.isPlaying) {
        state = PlayerState.playing(
          state.currentSong!,
          stateInfo.position,
          stateInfo.duration,
          stateInfo.speed,
        ).copyWith(playMode: state.playMode);
      } else {
        state = state.copyWith(
          isPlaying: stateInfo.isPlaying,
          position: stateInfo.position,
          duration: stateInfo.duration,
          speed: stateInfo.speed,
        );
      }
    }
  }

  /// 处理位置监听错误
  void _handlePositionError(Object error, StackTrace stackTrace) {
    Log.error('播放位置监听错误: $error\nStack trace: $stackTrace');
  }

  /// 状态更新方法 - 提供简洁的API
  void updateToLoading(Song song) => state = PlayerState.loading(song);
  
  void updateToPlaying(Song song, PlayerStateInfo stateInfo) => state = PlayerState.playing(
    song,
    stateInfo.position,
    stateInfo.duration,
    stateInfo.speed,
  ).copyWith(playMode: state.playMode);
  
  void updateToError(String error) => state = PlayerState.error(error);
  
  void updatePlaying(bool isPlaying) => state = state.copyWith(isPlaying: isPlaying);
  
  void updateVolume(double volume) => state = state.copyWith(volume: volume);
  
  void updateSpeed(double speed) => state = state.copyWith(speed: speed);
  
  void updatePosition(Duration position) => state = state.copyWith(position: position);
  
  void updatePlayMode(PlayMode playMode) => state = state.copyWith(playMode: playMode);
  
  void resetToInitial() => state = PlayerState.initial();
  
  PlayerState getCurrentState() => state;

  /// 播放控制
  Future<void> playSong(Song song) async {
    try {
      Log.info('开始播放: ${song.title}');
      state = PlayerState.loading(song);
      
      await _audioPlayerService.safePlay(song);
      
      final appBarNotifier = _ref.read(appBarStateNotifierProvider.notifier);
      appBarNotifier.updateTitle(song.title);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final stateInfo = _audioPlayerService.getPlayerStateInfo();
      updateToPlaying(song, stateInfo);
      
      Log.info('播放成功: ${song.title}');
    } catch (e, stackTrace) {
      Log.error('播放失败: $e\nStack trace: $stackTrace');
      updateToError('播放失败: $e');
    }
  }

  Future<void> pause() async {
    if (state.isPlaying) {
      await _audioPlayerService.safePause();
      updatePlaying(false);
    }
  }

  Future<void> resume() async {
    if (!state.isPlaying && state.currentSong != null) {
      await _audioPlayerService.safeResume();
      updatePlaying(true);
    }
  }

  Future<void> stop() async {
    await _audioPlayerService.safeStop();
    resetToInitial();
    
    final appBarNotifier = _ref.read(appBarStateNotifierProvider.notifier);
    appBarNotifier.updateTitle('播放器');
  }

  Future<void> seekTo(Duration position) async {
    if (state.currentSong != null) {
      await _audioPlayerService.safeSeekTo(position);
      updatePosition(position);
    }
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayerService.safeSetVolume(volume);
    updateVolume(volume);
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayerService.safeSetSpeed(speed);
    updateSpeed(speed);
  }

  void togglePlayMode() {
    final nextMode = PlayMode.values[(state.playMode.index + 1) % PlayMode.values.length];
    updatePlayMode(nextMode);
    Log.info('播放模式切换: ${nextMode.name}');
  }

  /// 播放控制方法
  void play() {
    if (state.currentSong != null) {
      playSong(state.currentSong!);
    }
  }

  Future<void> next() async {
    if (state.currentSong != null) {
      // 这里需要播放列表逻辑，暂时播放下一首
      Log.info('播放下一首');
    }
  }

  Future<void> previous() async {
    if (state.currentSong != null) {
      // 这里需要播放列表逻辑，暂时播放上一首
      Log.info('播放上一首');
    }
  }

  /// 播放列表管理
  List<Song> getPlaylist() {
    // 这里应该返回当前播放列表，暂时返回空列表
    return [];
  }

  void setPlaylist(List<Song> playlist, int index) {
    Log.info('设置播放列表: ${playlist.length}首歌曲, 索引: $index');
    // 这里需要实现播放列表设置逻辑
  }

  Future<void> playSongAtIndex(int index) async {
    final playlist = getPlaylist();
    if (index >= 0 && index < playlist.length) {
      playSong(playlist[index]);
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _positionSubscription.safeCancel();
    _audioPlayerService.safeDispose();
    super.dispose();
  }
}
