import 'package:just_audio/just_audio.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/domain/models/song.dart';

/// 基于just_audio的音频播放服务实现
class JustAudioPlayerService implements AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  Future<void> play(Song song) async {
    try {
      await _audioPlayer.setFilePath(song.data);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('播放歌曲失败: $e');
    }
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  @override
  Duration get currentPosition => _audioPlayer.position;

  @override
  Duration get duration => _audioPlayer.duration ?? Duration.zero;

  @override
  bool get isPlaying => _audioPlayer.playing;

  @override
  void dispose() {
    _audioPlayer.dispose();
  }
}