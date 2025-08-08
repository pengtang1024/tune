import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:tune/presentation/bloc/player/player_state.dart';
import 'package:tune/core/services/audio_service.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioService _audioService;
  final GetAllSongs _getAllSongs;
  List<Song> _songs = [];
  StreamSubscription? _positionSubscription;
  PlayMode _playMode = PlayMode.repeatAll;
  double _playbackSpeed = 1.0;

  PlayerBloc({
    required AudioService audioService,
    required GetAllSongs getAllSongs,
  })  : _audioService = audioService,
        _getAllSongs = getAllSongs,
        super(PlayerInitial()) {
    _init();
  }

  Future<void> _init() async {
    on<PlaySongEvent>(_onPlaySong);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<StopEvent>(_onStop);
    on<SkipToNextEvent>(_onSkipToNext);
    on<SkipToPreviousEvent>(_onSkipToPrevious);
    on<SeekToEvent>(_onSeekTo);
    on<SetVolumeEvent>(_onSetVolume);
    on<UpdateProgressEvent>(_onUpdateProgress);
    on<SetPlayModeEvent>(_onSetPlayMode);
    on<SetPlaybackSpeedEvent>(_onSetPlaybackSpeed);
    

    // 监听播放位置变化
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (state is PlayerPlaying || state is PlayerPaused) {
        add(UpdateProgressEvent(position));
      }
    });
  }


  Future<void> _onPlaySong(PlaySongEvent event, Emitter<PlayerState> emit) async {
    emit(PlayerLoading());
    
    try {
      // 获取所有歌曲
      if (_songs.isEmpty) {
        _songs = await _getAllSongs();
      }
      
      // 查找要播放的歌曲
      final song = _songs.firstWhere((s) => s.id == event.songId);
      
      // 播放指定歌曲
      await _audioService.playSong(song, _songs);
      
      emit(PlayerPlaying(
        song: song,
        position: Duration.zero,
        duration: Duration(milliseconds: song.duration),
        volume: 1.0,
      ));
    } catch (e) {
      // 处理错误
      emit(PlayerStopped());
    }
  }

  Future<void> _onTogglePlayPause(TogglePlayPauseEvent event, Emitter<PlayerState> emit) async {
    if (state is PlayerPlaying) {
      await _audioService.pause();
      final playingState = state as PlayerPlaying;
      emit(PlayerPaused(
        song: playingState.song,
        position: playingState.position,
        duration: playingState.duration,
        volume: playingState.volume,
      ));
    } else if (state is PlayerPaused) {
      await _audioService.play();
      final pausedState = state as PlayerPaused;
      emit(PlayerPlaying(
        song: pausedState.song,
        position: pausedState.position,
        duration: pausedState.duration,
        volume: pausedState.volume,
      ));
    }
  }

  Future<void> _onStop(StopEvent event, Emitter<PlayerState> emit) async {
    await _audioService.stop();
    emit(PlayerStopped());
  }

  Future<void> _onSkipToNext(SkipToNextEvent event, Emitter<PlayerState> emit) async {
    await _audioService.skipToNext();
    // 更新当前播放的歌曲状态
    if (state is PlayerPlaying || state is PlayerPaused) {
      final currentIndex = await _audioService.currentIndexStream.first;
      if (currentIndex != null && currentIndex < _songs.length) {
        final currentSong = _songs[currentIndex];
        final currentPosition = await _audioService.positionStream.first;
        final currentDuration = await _audioService.durationStream.first;
        final currentVolume = state is PlayerPlaying 
            ? (state as PlayerPlaying).volume 
            : (state as PlayerPaused).volume;
            
        if (state is PlayerPlaying) {
          emit(PlayerPlaying(
            song: currentSong,
            position: currentPosition,
            duration: currentDuration ?? Duration.zero,
            volume: currentVolume,
          ));
        } else {
          emit(PlayerPaused(
            song: currentSong,
            position: currentPosition,
            duration: currentDuration ?? Duration.zero,
            volume: currentVolume,
          ));
        }
      }
    }
  }

  Future<void> _onSkipToPrevious(SkipToPreviousEvent event, Emitter<PlayerState> emit) async {
    await _audioService.skipToPrevious();
    // 更新当前播放的歌曲状态
    if (state is PlayerPlaying || state is PlayerPaused) {
      final currentIndex = await _audioService.currentIndexStream.first;
      if (currentIndex != null && currentIndex < _songs.length) {
        final currentSong = _songs[currentIndex];
        final currentPosition = await _audioService.positionStream.first;
        final currentDuration = await _audioService.durationStream.first;
        final currentVolume = state is PlayerPlaying 
            ? (state as PlayerPlaying).volume 
            : (state as PlayerPaused).volume;
            
        if (state is PlayerPlaying) {
          emit(PlayerPlaying(
            song: currentSong,
            position: currentPosition,
            duration: currentDuration ?? Duration.zero,
            volume: currentVolume,
          ));
        } else {
          emit(PlayerPaused(
            song: currentSong,
            position: currentPosition,
            duration: currentDuration ?? Duration.zero,
            volume: currentVolume,
          ));
        }
      }
    }
  }

  Future<void> _onSeekTo(SeekToEvent event, Emitter<PlayerState> emit) async {
    await _audioService.seek(event.position);
    
    if (state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      emit(playingState.copyWith(position: event.position));
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(pausedState.copyWith(position: event.position));
    }
  }

  Future<void> _onSetVolume(SetVolumeEvent event, Emitter<PlayerState> emit) async {
    await _audioService.setVolume(event.volume);
    
    if (state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      emit(playingState.copyWith(volume: event.volume));
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(pausedState.copyWith(volume: event.volume));
    }
  }

  Future<void> _onUpdateProgress(UpdateProgressEvent event, Emitter<PlayerState> emit) async {
    if (state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      emit(playingState.copyWith(position: event.position));
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(pausedState.copyWith(position: event.position));
    }
  }

  Future<void> _onSetPlayMode(SetPlayModeEvent event, Emitter<PlayerState> emit) async {
    _playMode = event.playMode;
    
    // 根据播放模式设置音频播放器
    switch (_playMode) {
      case PlayMode.repeatAll:
        await _audioService.setLoopMode(just_audio.LoopMode.all);
        break;
      case PlayMode.repeatOne:
        await _audioService.setLoopMode(just_audio.LoopMode.one);
        break;
      case PlayMode.shuffle:
        await _audioService.setShuffleMode(true);
        break;
    }
  }

  Future<void> _onSetPlaybackSpeed(SetPlaybackSpeedEvent event, Emitter<PlayerState> emit) async {
    _playbackSpeed = event.speed;
    await _audioService.setSpeed(_playbackSpeed);
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}