import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:tune/data/services/media/i_audio_service.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_event.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final IAudioService _audioService;
  final GetAllSongs _getAllSongs;
  List<Song> _songs = [];
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  PlayMode _playMode = PlayMode.repeatAll;
  double _playbackSpeed = 1.0;
  int? _currentSongIndex;
  Set<int> _playedIndicesInShuffle = <int>{};

  PlayerBloc({
    required IAudioService audioService,
    required GetAllSongs getAllSongs,
  })  : _audioService = audioService,
        _getAllSongs = getAllSongs,
        super(PlayerInitial()) {
    _init();
  }

  /// 获取所有歌曲的公共方法
  Future<List<Song>> getAllSongs() async {
    try {
      final songs = await _getAllSongs();
      _songs = songs;
      return songs;
    } catch (e) {
      // 如果获取歌曲失败，返回空列表
      return [];
    }
  }

  Future<void> _init() async {
    on<PlaySongEvent>(_onPlaySong);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<StopEvent>(_onStop);
    on<SkipToNextEvent>(_onSkipToNext);
    on<SkipToPreviousEvent>(_onSkipToPrevious);
    on<UpdateProgressEvent>(_onUpdateProgress);
    on<SetVolumeEvent>(_onSetVolume);
    on<SetPlayModeEvent>(_onSetPlayMode);
    on<SetPlaybackSpeedEvent>(_onSetPlaybackSpeed);
    on<SeekToEvent>(_onSeekTo);
    on<PlayErrorEvent>(_onPlayError);

    // 监听播放位置变化
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (state is PlayerPlaying || state is PlayerPaused) {
        add(UpdateProgressEvent(position));
      }
    });

    // 监听播放器状态变化
    _playerStateSubscription = _audioService.playerStateStream.listen((playerState) {
      // 处理播放完成事件
      if (playerState.processingState == just_audio.ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
      // 处理播放错误 - 修复枚举常量错误
      else if (playerState.processingState == just_audio.ProcessingState.idle) {
        // 某些错误状态下可能会进入idle状态，这里作为错误处理
        _handlePlaybackError('播放失败，请检查文件');
      }
    });

    // 初始化歌曲列表
    unawaited(_initSongs());
  }

  /// 初始化歌曲列表
  Future<void> _initSongs() async {
    try {
      _songs = await _getAllSongs();
    } catch (e) {
      // Handle error silently
    }
  }

  /// 处理播放完成事件
  void _handlePlaybackCompleted() {
    try {
      if (_playMode == PlayMode.repeatOne) {
        // 单曲循环，重新播放当前歌曲
        if (_currentSongIndex != null && _currentSongIndex! < _songs.length) {
          add(PlaySongEvent(_songs[_currentSongIndex!].id));
        }
      } else if (_playMode == PlayMode.shuffle && _songs.isNotEmpty) {
        // 随机播放模式
        final availableIndices = List.generate(_songs.length, (index) => index)
            .where((index) => !_playedIndicesInShuffle.contains(index))
            .toList();
        
        if (availableIndices.isEmpty) {
          // 如果所有歌曲都播放过了，重置列表
          _playedIndicesInShuffle.clear();
          availableIndices.addAll(List.generate(_songs.length, (index) => index));
        }
        
        // 使用更可靠的随机数生成方式
        final random = Random(DateTime.now().millisecondsSinceEpoch);
        final randomIndex = availableIndices[random.nextInt(availableIndices.length)];
        _playedIndicesInShuffle.add(randomIndex);
        _currentSongIndex = randomIndex;
        add(PlaySongEvent(_songs[randomIndex].id));
      } else {
        // 列表循环模式
        if (_songs.isNotEmpty) {
          add(SkipToNextEvent());
        } else {
          // 没有歌曲时进入停止状态
          add(StopEvent());
        }
      }
    } catch (e) {
      // 添加错误处理
      add(PlayErrorEvent("播放完成处理失败: $e"));
    }
  }

  /// 处理播放错误事件
  void _handlePlaybackError(String message) {
    add(PlayErrorEvent(message));
  }

  /// 处理播放歌曲事件
  Future<void> _onPlaySong(PlaySongEvent event, Emitter<PlayerState> emit) async {
    emit(PlayerLoading());
    try {
      final songIndex = _songs.indexWhere((s) => s.id == event.songId);
      if (songIndex == -1) {
        throw Exception('歌曲未找到');
      }
      
      _currentSongIndex = songIndex;
      
      final song = _songs[songIndex];
      await _audioService.playSong(song, _songs); // 传递歌曲和播放列表参数
      
      // 只有在随机播放模式下才需要管理已播放索引
      if (_playMode == PlayMode.shuffle) {
        // 如果是随机播放模式且当前歌曲不在已播放列表中，则添加
        if (!_playedIndicesInShuffle.contains(songIndex)) {
          _playedIndicesInShuffle.add(songIndex);
        }
      }

      // 获取歌曲时长
      final durationStream = _audioService.durationStream;
      Duration? duration;
      final durationSubscription = durationStream.take(1).listen((d) {
        duration = d;
      });

      // 等待一段时间以获取时长信息
      await Future.delayed(const Duration(milliseconds: 100));
      await durationSubscription.cancel();

      emit(PlayerPlaying(
        song: song,
        position: Duration.zero,
        duration: duration ?? Duration.zero,
        volume: 1.0,
        speed: _playbackSpeed,
        playMode: _playMode,
      ));
    } catch (e) {
      emit(PlayerError(message: e.toString()));
      // 出错时尝试播放下一首
      add(SkipToNextEvent());
    }
  }

  /// 处理切换播放/暂停事件
  void _onTogglePlayPause(TogglePlayPauseEvent event, Emitter<PlayerState> emit) {
    if (state is PlayerPlaying) {
      _audioService.pause();
      final currentState = state as PlayerPlaying;
      emit(PlayerPaused(
        song: currentState.song,
        position: currentState.position,
        duration: currentState.duration,
        volume: currentState.volume,
        speed: currentState.speed,
        playMode: currentState.playMode,
      ));
    } else if (state is PlayerPaused) {
      _audioService.play(); // 恢复播放
      final currentState = state as PlayerPaused;
      emit(PlayerPlaying(
        song: currentState.song,
        position: currentState.position,
        duration: currentState.duration,
        volume: currentState.volume,
        speed: currentState.speed,
        playMode: currentState.playMode,
      ));
    }
  }

  /// 处理停止事件
  void _onStop(StopEvent event, Emitter<PlayerState> emit) {
    _audioService.stop();
    emit(PlayerStopped());
  }

  /// 处理跳到下一首事件
  void _onSkipToNext(SkipToNextEvent event, Emitter<PlayerState> emit) {
    if (_playMode == PlayMode.shuffle && _songs.isNotEmpty) {
      // 随机播放模式
      final availableIndices = List.generate(_songs.length, (index) => index)
          .where((index) => !_playedIndicesInShuffle.contains(index))
          .toList();
      
      if (availableIndices.isEmpty) {
        // 如果所有歌曲都播放过了，重置列表
        _playedIndicesInShuffle.clear();
        availableIndices.addAll(List.generate(_songs.length, (index) => index));
      }
      
      // 使用更可靠的随机数生成方式
      final random = Random(DateTime.now().millisecondsSinceEpoch);
      final randomIndex = availableIndices[random.nextInt(availableIndices.length)];
      _playedIndicesInShuffle.add(randomIndex);
      _currentSongIndex = randomIndex;
      add(PlaySongEvent(_songs[randomIndex].id));
    } else {
      // 其他播放模式，让音频服务处理
      _audioService.skipToNext().catchError((error) {
        // 如果skipToNext失败，尝试播放列表中的下一首
        if (_currentSongIndex != null && _songs.isNotEmpty) {
          final nextIndex = (_currentSongIndex! + 1) % _songs.length;
          _currentSongIndex = nextIndex;
          add(PlaySongEvent(_songs[nextIndex].id));
        }
      });
    }
  }

  /// 处理跳到上一首事件
  void _onSkipToPrevious(SkipToPreviousEvent event, Emitter<PlayerState> emit) {
    _audioService.skipToPrevious();
  }

  /// 处理更新进度事件
  void _onUpdateProgress(UpdateProgressEvent event, Emitter<PlayerState> emit) {
    if (state is PlayerPlaying) {
      final currentState = state as PlayerPlaying;
      emit(currentState.copyWith(
        position: event.position,
        speed: currentState.speed, // 显式传递播放速度信息
        playMode: currentState.playMode, // 显式传递播放模式信息
      ));
    } else if (state is PlayerPaused) {
      final currentState = state as PlayerPaused;
      emit(currentState.copyWith(
        position: event.position,
        speed: currentState.speed, // 显式传递播放速度信息
        playMode: currentState.playMode, // 显式传递播放模式信息
      ));
    }
  }

  /// 处理设置音量事件
  void _onSetVolume(SetVolumeEvent event, Emitter<PlayerState> emit) {
    _audioService.setVolume(event.volume);
  }

  /// 处理设置播放模式事件
  void _onSetPlayMode(SetPlayModeEvent event, Emitter<PlayerState> emit) {
    _playMode = event.playMode;
    switch (event.playMode) {
      case PlayMode.repeatAll:
        _audioService.setLoopMode(just_audio.LoopMode.all);
        _audioService.setShuffleMode(false);
        break;
      case PlayMode.repeatOne:
        _audioService.setLoopMode(just_audio.LoopMode.one);
        _audioService.setShuffleMode(false);
        break;
      case PlayMode.shuffle:
        _audioService.setLoopMode(just_audio.LoopMode.all);
        _audioService.setShuffleMode(true);
        _playedIndicesInShuffle.clear();
        // 如果当前有正在播放的歌曲，将其添加到已播放列表中
        if (_currentSongIndex != null) {
          _playedIndicesInShuffle.add(_currentSongIndex!);
        }
        break;
    }
    
    // 更新当前状态中的播放模式
    if (state is PlayerPlaying) {
      final currentState = state as PlayerPlaying;
      emit(currentState.copyWith(playMode: event.playMode));
    } else if (state is PlayerPaused) {
      final currentState = state as PlayerPaused;
      emit(currentState.copyWith(playMode: event.playMode));
    }
  }

  /// 处理设置播放速度事件
  void _onSetPlaybackSpeed(SetPlaybackSpeedEvent event, Emitter<PlayerState> emit) {
    _playbackSpeed = event.speed;
    _audioService.setSpeed(event.speed);
  }

  /// 处理跳转事件
  void _onSeekTo(SeekToEvent event, Emitter<PlayerState> emit) {
    _audioService.seek(event.position);
  }

  /// 处理播放错误事件
  void _onPlayError(PlayErrorEvent event, Emitter<PlayerState> emit) {
    emit(PlayerError(message: event.message));
    // 尝试自动跳到下一首
    add(SkipToNextEvent());
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioService.dispose();
    return super.close();
  }
}