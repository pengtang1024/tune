import 'package:just_audio/just_audio.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';
import 'dart:io' show Platform;

/// 基于just_audio的音频播放服务实现
class JustAudioPlayerService implements AudioPlayerService {
  AudioPlayer? _audioPlayer;

  /// 初始化服务
  @override
  Future<void> init() async {
    try {
      _audioPlayer = AudioPlayer();
      Log.info('音频播放器初始化成功');
    } catch (e) {
      Log.error('初始化音频播放器失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> play(Song song) async {
    try {
      // 确保播放器已初始化
      if (_audioPlayer == null) {
        await init();
      }
      
      // 优先使用uri字段，如果uri为空则使用data字段
      final String? audioPath = song.uri ?? song.data;
      
      // 检查音频路径是否为空
      if (audioPath == null || audioPath.isEmpty) {
        throw Exception('音频文件路径为空');
      }
      
      await _audioPlayer!.setAudioSource(AudioSource.uri(Uri.file(audioPath)));
      await _audioPlayer!.play();
    } catch (e) {
      Log.error('播放音频失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
      }
    } catch (e) {
      Log.error('暂停播放失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> resume() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.play();
      }
    } catch (e) {
      Log.error('恢复播放失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
    } catch (e) {
      Log.error('停止播放失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.seek(position);
      }
    } catch (e) {
      Log.error('跳转到指定位置失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.setVolume(volume);
      }
    } catch (e) {
      Log.error('设置音量失败: $e');
      rethrow;
    }
  }

  @override
  Duration get currentPosition {
    try {
      return _audioPlayer?.position ?? Duration.zero;
    } catch (e) {
      Log.error('获取当前播放位置失败: $e');
      return Duration.zero;
    }
  }

  @override
  Duration get duration {
    try {
      return _audioPlayer?.duration ?? Duration.zero;
    } catch (e) {
      // Windows平台有时在获取duration时会抛出异常
      Log.error('获取音频时长失败: $e');
      return Duration.zero;
    }
  }

  @override
  bool get isPlaying {
    try {
      return _audioPlayer?.playing ?? false;
    } catch (e) {
      Log.error('获取播放状态失败: $e');
      return false;
    }
  }

  @override
  void dispose() {
    try {
      _audioPlayer?.dispose();
      _audioPlayer = null;
    } catch (e) {
      Log.error('释放音频播放器资源失败: $e');
    }
  }
}