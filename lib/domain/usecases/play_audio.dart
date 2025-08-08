import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/repositories/audio_repository.dart';

class PlayAudioParams {
  final Song song;
  
  PlayAudioParams({required this.song});
}

class PlayAudio {
  final AudioRepository repository;

  PlayAudio(this.repository);

  Future<void> call(PlayAudioParams params) async {
    // 在实际应用中，这里可能需要调用系统播放器或音频服务
    // 目前我们只是调用仓库中的播放方法
    await repository.playSong(params.song);
  }
}