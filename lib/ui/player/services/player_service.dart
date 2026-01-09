import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/player/extensions/player_control_extension.dart';
import 'package:tune/ui/player/extensions/playlist_manager_extension.dart';
import 'package:tune/ui/player/extensions/play_history_extension.dart';
import 'package:tune/ui/player/extensions/player_state_extension.dart';
import 'package:tune/ui/player/extensions/resource_management_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/utils/logger.dart';

/// 播放器服务
/// 封装播放器核心功能，提供简洁的API
class PlayerService {
  final Ref _ref;
  late final AudioPlayerService _audioPlayerService;
  StreamSubscription? _positionSubscription;
  List<Song> _playlist = [];
  final List<Song> _playHistory = [];
  int _currentIndex = -1;

  PlayerService(this._ref) {
    _audioPlayerService = _ref.read(audioPlayerServiceProvider);
    _initialize();
  }

  /// 获取当前播放状态
  PlayerState getCurrentState() {
    return _ref.read(playerStateNotifierProvider);
  }

  /// 初始化播放器
  void _initialize() {
    try {
      _positionSubscription = _audioPlayerService.createPositionStream()
          .listen(_handlePositionUpdate, onError: _handlePositionError);
    } catch (e, stackTrace) {
      Log.error('播放器初始化失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 处理位置更新
  void _handlePositionUpdate(Duration position) {
    final currentState = _ref.read(playerStateNotifierProvider);
    if (currentState.currentSong != null) {
      final stateInfo = _audioPlayerService.getPlayerStateInfo();
      final notifier = _ref.read(playerStateNotifierProvider.notifier);
      notifier.updateToPlaying(currentState.currentSong!, stateInfo);
    }
  }

  /// 处理位置监听错误
  void _handlePositionError(Object error, StackTrace stackTrace) {
    Log.error('播放位置监听错误: $error\nStack trace: $stackTrace');
  }

  /// 设置播放列表
  void setPlaylist(List<Song> playlist, int initialIndex) {
    _playlist = playlist;
    _currentIndex = initialIndex;
    Log.info('播放列表设置: ${playlist.length}首歌曲, 初始索引: $initialIndex');
  }

  /// 播放歌曲
  Future<void> playSong(Song song) async {
    try {
      Log.info('开始播放: ${song.title}');
      _playHistory.addToHistory(song);
      
      final notifier = _ref.read(playerStateNotifierProvider.notifier);
      notifier.updateToLoading(song);
      
      await _audioPlayerService.safePlay(song);
      
      final appBarNotifier = _ref.read(appBarStateNotifierProvider.notifier);
      appBarNotifier.updateTitle(song.title);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final stateInfo = _audioPlayerService.getPlayerStateInfo();
      notifier.updateToPlaying(song, stateInfo);
      
      Log.info('播放成功: ${song.title}');
    } catch (e, stackTrace) {
      Log.error('播放失败: $e\nStack trace: $stackTrace');
      _ref.read(playerStateNotifierProvider.notifier).updateToError('播放失败: $e');
    }
  }

  /// 播放控制
  Future<void> pause() async {
    final notifier = _ref.read(playerStateNotifierProvider.notifier);
    final currentState = notifier.getCurrentState();
    
    if (currentState.isPlayingState) {
      await _audioPlayerService.safePause();
      notifier.updatePlaying(false);
    }
  }

  Future<void> resume() async {
    final notifier = _ref.read(playerStateNotifierProvider.notifier);
    final currentState = notifier.getCurrentState();
    
    if (!currentState.isPlayingState && currentState.isValidState) {
      await _audioPlayerService.safeResume();
      notifier.updatePlaying(true);
    }
  }

  Future<void> stop() async {
    await _audioPlayerService.safeStop();
    _ref.read(playerStateNotifierProvider.notifier).resetToInitial();
    
    final appBarNotifier = _ref.read(appBarStateNotifierProvider.notifier);
    appBarNotifier.updateTitle('播放器');
  }

  /// 导航控制
  void next() => _navigateInPlaylist(true);
  void previous() => _navigateInPlaylist(false);

  void _navigateInPlaylist(bool isNext) {
    if (_playlist.isEmpty) return;
    
    _currentIndex = isNext 
        ? _playlist.getNextIndex(_currentIndex, getCurrentState().playMode)
        : _playlist.getPreviousIndex(_currentIndex, getCurrentState().playMode);
        
    final song = _playlist.safeGet(_currentIndex);
    if (song != null) {
      playSong(song);
    }
  }

  /// 播放列表管理
  void addToPlaylist(Song song) => _playlist.safeAdd(song, context: '添加');
  void removeFromPlaylist(int index) {
    final removedSong = _playlist.safeRemoveAt(index, context: '移除');
    if (removedSong != null) {
      _adjustIndexAfterRemoval(index);
    }
  }

  void _adjustIndexAfterRemoval(int removedIndex) {
    if (removedIndex < _currentIndex) {
      _currentIndex--;
    } else if (removedIndex == _currentIndex) {
      if (_playlist.isNotEmpty) {
        _currentIndex = _currentIndex >= _playlist.length ? 0 : _currentIndex;
      } else {
        _currentIndex = -1;
        stop();
      }
    }
  }

  void clearPlaylist() {
    _playlist.safeClear(context: '清空播放列表');
    _currentIndex = -1;
    stop();
  }

  /// 属性设置
  Future<void> setVolume(double volume) async {
    await _audioPlayerService.safeSetVolume(volume);
    _ref.read(playerStateNotifierProvider.notifier).updateVolume(volume);
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayerService.safeSetSpeed(speed);
    _ref.read(playerStateNotifierProvider.notifier).updateSpeed(speed);
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayerService.safeSeekTo(position);
    _ref.read(playerStateNotifierProvider.notifier).updatePosition(position);
  }

  void togglePlayMode() {
    final currentState = getCurrentState();
    final nextMode = PlayMode.values[(currentState.playMode.index + 1) % PlayMode.values.length];
    _ref.read(playerStateNotifierProvider.notifier).updatePlayMode(nextMode);
    Log.info('播放模式切换: ${nextMode.name}');
  }

  /// 获取器
  List<Song> get playlist => _playlist;
  List<Song> get history => List.unmodifiable(_playHistory);
  int get currentIndex => _currentIndex;

  /// 释放资源
  void dispose() {
    _positionSubscription.safeCancel();
    _audioPlayerService.safeDispose();
  }
}
