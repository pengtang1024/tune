import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/utils/logger.dart';

/// 播放器状态管理器
class PlayerStateNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  late final AudioPlayerService _audioPlayerService;
  StreamSubscription? _positionSubscription;
  List<Song> _playlist = [];
  final List<Song> _playHistory = []; // 播放历史记录
  int _currentIndex = -1;
  static const int _maxHistorySize = 50; // 最大历史记录数量

  PlayerStateNotifier(this._ref) : super(PlayerState.initial()) {
    _audioPlayerService = _ref.read(audioPlayerServiceProvider);
    _initializePlayer();
  }

  /// 初始化播放器
  void _initializePlayer() {
    try {
      // 实时更新播放位置
      _positionSubscription = Stream.periodic(const Duration(milliseconds: 100))
          .listen(
            (_) {
              try {
                if (state.currentSong != null) {
                  final isPlaying = _audioPlayerService.isPlaying;
                  final position = _audioPlayerService.currentPosition;
                  final duration = _audioPlayerService.duration;
                  final speed = _audioPlayerService.speed;

                  // 只有当状态发生变化时才更新
                  if (state.isPlaying != isPlaying ||
                      state.position != position ||
                      state.duration != duration ||
                      state.speed != speed) {
                    // 如果当前处于加载状态但播放器已经在播放，则更新状态
                    if (state.isLoading && isPlaying) {
                      state = PlayerState.playing(
                        state.currentSong!,
                        position,
                        duration,
                        speed,
                      ).copyWith(playMode: state.playMode);
                    } else {
                      state = state.copyWith(
                        isPlaying: isPlaying,
                        position: position,
                        duration: duration,
                        speed: speed,
                      );
                    }
                  }
                }
              } catch (e, stackTrace) {
                Log.error('更新播放位置时出错: $e\nStack trace: $stackTrace');
              }
            },
            onError: (error, stackTrace) {
              Log.error('播放位置监听流出错: $error\nStack trace: $stackTrace');
            },
          );
    } catch (e, stackTrace) {
      Log.error('初始化播放器时出错: $e\nStack trace: $stackTrace');
    }
  }

  /// 设置播放列表
  void setPlaylist(List<Song> playlist, int initialIndex) {
    try {
      _playlist = playlist;
      _currentIndex = initialIndex;
      Log.info('播放列表设置成功，共${playlist.length}首歌曲，初始索引: $initialIndex');
    } catch (e, stackTrace) {
      Log.error('设置播放列表时出错: $e\nStack trace: $stackTrace');
    }
  }

  /// 播放歌曲
  Future<void> playSong(Song song) async {
    try {
      Log.info('开始播放歌曲: ${song.title}');

      // 添加到播放历史记录
      _addToPlayHistory(song);

      // 更新状态为加载中
      state = PlayerState.loading(song);

      // 播放歌曲
      await _audioPlayerService.play(song);

      // 更新应用栏标题为歌曲名称
      final appBarNotifier = _ref.read(appBarStateNotifierProvider.notifier);
      appBarNotifier.updateTitle(song.title);

      // 等待一小段时间确保播放器状态稳定
      await Future.delayed(const Duration(milliseconds: 100));

      // 更新状态为播放中
      state = PlayerState.playing(
        song,
        _audioPlayerService.currentPosition,
        _audioPlayerService.duration,
        _audioPlayerService.speed,
      ).copyWith(playMode: state.playMode);

      Log.info('歌曲播放成功: ${song.title}');
    } catch (e, stackTrace) {
      Log.error('播放歌曲失败: $e\nStack trace: $stackTrace');
      // 播放出错，更新状态为错误
      state = PlayerState.error('播放歌曲失败: $e');
    }
  }

  /// 添加歌曲到播放历史记录
  void _addToPlayHistory(Song song) {
    try {
      // 检查歌曲是否已经在历史记录中
      final existingIndex = _playHistory.indexWhere((s) => s.id == song.id);
      if (existingIndex != -1) {
        // 如果存在，将其移到列表开头
        _playHistory.removeAt(existingIndex);
      }

      // 将歌曲添加到历史记录开头
      _playHistory.insert(0, song);

      // 保持历史记录大小在限制范围内
      if (_playHistory.length > _maxHistorySize) {
        _playHistory.removeRange(_maxHistorySize, _playHistory.length);
      }

      Log.info('添加歌曲到播放历史记录: ${song.title}');
    } catch (e, stackTrace) {
      Log.error('添加歌曲到播放历史记录失败: $e', stackTrace);
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    try {
      if (state.isPlaying && state.currentSong != null) {
        await _audioPlayerService.pause();
        state = state.copyWith(isPlaying: false);
        Log.info('暂停播放成功');
      }
    } catch (e, stackTrace) {
      Log.error('暂停播放失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 继续播放
  Future<void> play() async {
    try {
      if (!state.isPlaying && state.currentSong != null) {
        await _audioPlayerService.resume();
        state = state.copyWith(isPlaying: true);
        Log.info('继续播放成功');
      }
    } catch (e, stackTrace) {
      Log.error('继续播放失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayerService.stop();
      state = PlayerState.initial();

      // 恢复应用栏标题为默认标题
      final appBarNotifier = _ref.read(appBarStateNotifierProvider.notifier);
      appBarNotifier.updateTitle('播放器');

      Log.info('停止播放成功');
    } catch (e, stackTrace) {
      Log.error('停止播放失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    try {
      if (state.currentSong != null) {
        await _audioPlayerService.seekTo(position);
        state = state.copyWith(position: position);
        Log.info('跳转到位置: ${position.inSeconds}秒');
      }
    } catch (e, stackTrace) {
      Log.error('跳转到指定位置失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayerService.setVolume(volume);
      state = state.copyWith(volume: volume);
      Log.info('音量设置为: $volume');
    } catch (e, stackTrace) {
      Log.error('设置音量失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 设置播放速度
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayerService.setSpeed(speed);
      state = state.copyWith(speed: speed);
      Log.info('播放速度设置为: $speed');
    } catch (e, stackTrace) {
      Log.error('设置播放速度失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 切换播放模式
  void togglePlayMode() {
    try {
      final nextMode =
          PlayMode.values[(state.playMode.index + 1) % PlayMode.values.length];
      state = state.copyWith(playMode: nextMode);
      Log.info('播放模式切换为: ${nextMode.name}');
    } catch (e, stackTrace) {
      Log.error('切换播放模式失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 播放下一首
  void next() {
    try {
      if (_playlist.isEmpty) {
        Log.info('播放列表为空，无法播放下一首');
        return;
      }

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

      Log.info('播放下一首歌曲，索引: $_currentIndex');
      playSong(_playlist[_currentIndex]);
    } catch (e, stackTrace) {
      Log.error('播放下一首失败: $e', stackTrace);
    }
  }

  /// 播放上一首
  void previous() {
    try {
      if (_playlist.isEmpty) {
        Log.info('播放列表为空，无法播放上一首');
        return;
      }

      switch (state.playMode) {
        case PlayMode.sequential:
          _currentIndex =
              (_currentIndex - 1 + _playlist.length) % _playlist.length;
          break;
        case PlayMode.repeatOne:
          // 保持当前索引不变
          break;
        case PlayMode.shuffle:
          _currentIndex = Random().nextInt(_playlist.length);
          break;
      }

      Log.info('播放上一首歌曲，索引: $_currentIndex');
      playSong(_playlist[_currentIndex]);
    } catch (e, stackTrace) {
      Log.error('播放上一首失败: $e', stackTrace);
    }
  }

  /// 播放列表中的指定索引歌曲
  void playSongAtIndex(int index) {
    try {
      if (index >= 0 && index < _playlist.length) {
        _currentIndex = index;
        Log.info('播放列表中索引为 $index 的歌曲');
        playSong(_playlist[index]);
      } else {
        Log.info('索引 $index 超出播放列表范围');
      }
    } catch (e, stackTrace) {
      Log.error('播放指定索引歌曲失败: $e', stackTrace);
    }
  }

  /// 获取当前播放列表
  List<Song> getPlaylist() {
    return _playlist;
  }

  /// 获取播放历史记录
  List<Song> getPlayHistory() {
    return List.unmodifiable(_playHistory);
  }

  /// 添加歌曲到播放列表
  void addSongToPlaylist(Song song) {
    try {
      _playlist.add(song);
      Log.info('添加歌曲到播放列表: ${song.title}');
    } catch (e, stackTrace) {
      Log.error('添加歌曲到播放列表失败: $e\nStack trace: $stackTrace');
      // 可以考虑添加更多错误处理逻辑，如通知用户等
    }
  }

  /// 从播放列表移除歌曲
  void removeSongFromPlaylist(int index) {
    try {
      if (index >= 0 && index < _playlist.length) {
        final song = _playlist[index];
        _playlist.removeAt(index);

        // 如果删除的是当前播放歌曲之前的歌曲，需要调整当前索引
        if (index < _currentIndex) {
          _currentIndex--;
        }
        // 如果删除的是当前播放歌曲，需要处理播放状态
        else if (index == _currentIndex && _playlist.isNotEmpty) {
          // 如果删除的是最后一首歌，播放第一首
          if (_currentIndex >= _playlist.length) {
            _currentIndex = 0;
          }
        }
        // 如果播放列表为空，停止播放
        else if (_playlist.isEmpty) {
          _currentIndex = -1;
          stop();
        }

        Log.info('从播放列表移除歌曲: ${song.title}');
      }
    } catch (e, stackTrace) {
      Log.error('从播放列表移除歌曲失败: $e\nStack trace: $stackTrace');
      // 可以考虑添加更多错误处理逻辑，如通知用户等
    }
  }

  /// 清空播放列表
  void clearPlaylist() {
    try {
      _playlist.clear();
      _currentIndex = -1;
      stop();
      Log.info('清空播放列表');
    } catch (e, stackTrace) {
      Log.error('清空播放列表失败: $e\nStack trace: $stackTrace');
      // 可以考虑添加更多错误处理逻辑，如通知用户等
    }
  }

  /// 释放资源
  @override
  void dispose() {
    try {
      _positionSubscription?.cancel();
      _audioPlayerService.dispose();
      Log.info('播放器状态管理器资源释放成功');
    } catch (e, stackTrace) {
      Log.error('释放播放器状态管理器时出错: $e\nStack trace: $stackTrace');
      // 可以考虑添加更多错误处理逻辑
    } finally {
      // 确保调用父类的dispose方法
      super.dispose();
    }
  }
}
