import 'dart:async';

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
  PlayMode _playMode = PlayMode.repeatAll;
  double _playbackSpeed = 1.0;

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

    // 监听播放状态变化
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (state is PlayerPlaying) {
        add(UpdateProgressEvent(position));
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

  /// 处理播放歌曲事件
  Future<void> _onPlaySong(PlaySongEvent event, Emitter<PlayerState> emit) async {
    emit(PlayerLoading());
    try {
      final song = _songs.firstWhere((s) => s.id == event.songId);
      await _audioService.playSong(song, _songs); // 传递歌曲和播放列表参数

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
      ));
    } catch (e) {
      emit(PlayerError(message: e.toString()));
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
      ));
    } else if (state is PlayerPaused) {
      _audioService.play(); // 恢复播放
      final currentState = state as PlayerPaused;
      emit(PlayerPlaying(
        song: currentState.song,
        position: currentState.position,
        duration: currentState.duration,
        volume: currentState.volume,
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
    _audioService.skipToNext();
  }

  /// 处理跳到上一首事件
  void _onSkipToPrevious(SkipToPreviousEvent event, Emitter<PlayerState> emit) {
    _audioService.skipToPrevious();
  }

  /// 处理更新进度事件
  void _onUpdateProgress(UpdateProgressEvent event, Emitter<PlayerState> emit) {
    if (state is PlayerPlaying) {
      final currentState = state as PlayerPlaying;
      emit(currentState.copyWith(position: event.position));
    } else if (state is PlayerPaused) {
      final currentState = state as PlayerPaused;
      emit(currentState.copyWith(position: event.position));
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
        break;
      case PlayMode.repeatOne:
        _audioService.setLoopMode(just_audio.LoopMode.one);
        break;
      case PlayMode.shuffle:
        _audioService.setShuffleMode(true);
        break;
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

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _audioService.dispose();
    return super.close();
  }
}
