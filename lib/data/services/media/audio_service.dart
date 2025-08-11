import 'package:just_audio/just_audio.dart' hide LoopMode;
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:rxdart/rxdart.dart';
import 'package:tune/data/services/media/i_audio_service.dart';
import 'package:tune/domain/entities/song.dart';

/// 音频服务实现类
class AudioService implements IAudioService {
  final AudioPlayer _audioPlayer;

  AudioService({required AudioPlayer audioPlayer}) : _audioPlayer = audioPlayer;

  @override
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  @override
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  @override
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  @override
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;

  @override
  Stream<SequenceState?> get sequenceStateStream => _audioPlayer.sequenceStateStream;

  @override
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

  @override
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

    await _audioPlayer.setAudioSources(
      audioSources,
      preload: false,
    );
  }

  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  @override
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

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await _audioPlayer.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _audioPlayer.seekToPrevious();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  @override
  Future<void> setLoopMode(LoopMode loopMode) async {
    await _audioPlayer.setLoopMode(loopMode);
  }

  @override
  Future<void> setShuffleMode(bool shuffle) async {
    await _audioPlayer.setShuffleModeEnabled(shuffle);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
  }
}
