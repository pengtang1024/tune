import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// 基于just_audio的音频播放服务实现
class JustAudioPlayerService implements AudioPlayerService {
  AudioPlayer? _audioPlayer;

  /// 初始化服务
  @override
  Future<void> init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      _audioPlayer = AudioPlayer();
      Log.info('音频播放器初始化完成，已配置媒体会话');
    } catch (e, stackTrace) {
      Log.error('初始化音频播放器失败: $e\nStack trace: $stackTrace');
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

      // 使用song.uri作为音频路径
      final String audioPath = song.uri;

      // 检查音频路径是否为空
      if (audioPath.isEmpty) {
        Log.error('音频文件路径为空');
        throw Exception('音频文件路径为空');
      }

      Log.info('尝试播放音频文件: $audioPath');

      // 释放之前的音频源以节省内存
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.setAudioSource(AudioSource.uri(Uri.file(audioPath)));
        await _audioPlayer!.play();
      }
      Log.info('音频播放成功');
    } catch (e, stackTrace) {
      Log.error('播放音频失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
      }
    } catch (e, stackTrace) {
      Log.error('暂停播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> resume() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.play();
      }
    } catch (e, stackTrace) {
      Log.error('恢复播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
    } catch (e, stackTrace) {
      Log.error('停止播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.seek(position);
      }
    } catch (e, stackTrace) {
      Log.error('跳转到指定位置失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      if (_audioPlayer != null) {
        // 限制音量范围在0.0到1.0之间
        final clampedVolume = volume.clamp(0.0, 1.0);
        await _audioPlayer!.setVolume(clampedVolume);
      }
    } catch (e, stackTrace) {
      Log.error('设置音量失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      if (_audioPlayer != null) {
        // 限制播放速度范围在0.25到2.0之间
        final clampedSpeed = speed.clamp(0.25, 2.0);
        await _audioPlayer!.setSpeed(clampedSpeed);
      }
    } catch (e, stackTrace) {
      Log.error('设置播放速度失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Duration get currentPosition {
    try {
      return _audioPlayer?.position ?? Duration.zero;
    } catch (e, stackTrace) {
      Log.error('获取当前播放位置失败: $e\nStack trace: $stackTrace');
      return Duration.zero;
    }
  }

  @override
  Duration get duration {
    try {
      return _audioPlayer?.duration ?? Duration.zero;
    } catch (e, stackTrace) {
      // Windows平台有时在获取duration时会抛出异常
      Log.error('获取音频时长失败: $e\nStack trace: $stackTrace');
      return Duration.zero;
    }
  }

  @override
  bool get isPlaying {
    try {
      return _audioPlayer?.playing ?? false;
    } catch (e, stackTrace) {
      Log.error('获取播放状态失败: $e\nStack trace: $stackTrace');
      return false;
    }
  }

  @override
  double get speed {
    try {
      return _audioPlayer?.speed ?? 1.0;
    } catch (e, stackTrace) {
      Log.error('获取播放速度失败: $e\nStack trace: $stackTrace');
      return 1.0;
    }
  }

  @override
  void dispose() {
    try {
      _audioPlayer?.dispose();
      _audioPlayer = null;
      Log.info('音频播放器资源释放成功');
    } catch (e, stackTrace) {
      Log.error('释放音频播放器资源失败: $e\nStack trace: $stackTrace');
    }
  }
}
