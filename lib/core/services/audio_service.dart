import 'package:just_audio/just_audio.dart' hide LoopMode;
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:rxdart/rxdart.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:tune/domain/entities/song.dart';

class AudioService {
  final AudioPlayer _audioPlayer = DependencyInjection().audioPlayer;
  
  // 播放状态流
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  
  // 当前播放位置流
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  
  // 总时长流
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  
  // 当前索引流
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  
  // 播放列表流
  Stream<SequenceState?> get sequenceStateStream => _audioPlayer.sequenceStateStream;
  
  // 组合流，包含播放状态、位置和时长
  Stream<PlaybackState> get playbackStateStream => Rx.combineLatest3(
        _audioPlayer.playerStateStream,
        _audioPlayer.positionStream,
        _audioPlayer.durationStream,
        (playerState, position, duration) => PlaybackState(
          playerState: playerState,
          position: position,
          duration: duration,
        ),
      );

  // 设置播放列表
  Future<void> setPlaylist(List<Song> songs) async {
    final audioSources = songs
        .map((song) => AudioSource.uri(
              Uri.parse(song.uri),
              tag: MediaItem(
                id: song.id.toString(),
                title: song.title,
                artist: song.artist,
              ),
            ))
        .toList();
    
    await _audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: 0,
      preload: false,
    );
  }
  
  // 播放
  Future<void> play() async {
    await _audioPlayer.play();
  }
  
  // 播放指定歌曲
  Future<void> playSong(Song song, List<Song> playlist) async {
    try {
      // 先设置播放列表
      await setPlaylist(playlist);
      
      // 找到要播放的歌曲在播放列表中的索引
      final index = playlist.indexWhere((s) => s.id == song.id);
      
      // 跳转到指定歌曲并播放
      if (index != -1) {
        await _audioPlayer.seek(Duration.zero, index: index);
        await _audioPlayer.play();
      } else {
        // 如果没找到歌曲，则直接播放该歌曲
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(song.uri)),
        );
        await _audioPlayer.play();
      }
    } catch (e) {
      // 处理播放错误
      rethrow;
    }
  }
  
  // 暂停
  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  // 停止
  Future<void> stop() async {
    await _audioPlayer.stop();
  }
  
  // 跳到指定位置
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  // 跳到下一首
  Future<void> skipToNext() async {
    await _audioPlayer.seekToNext();
  }
  
  // 跳到上一首
  Future<void> skipToPrevious() async {
    await _audioPlayer.seekToPrevious();
  }
  
  // 设置音量
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }
  
  // 设置播放模式
  Future<void> setLoopMode(LoopMode loopMode) async {
    await _audioPlayer.setLoopMode(loopMode);
  }
  
  // 设置随机播放模式
  Future<void> setShuffleMode(bool shuffle) async {
    await _audioPlayer.setShuffleModeEnabled(shuffle);
  }
  
  // 设置播放速度
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }
  
  // 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}

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