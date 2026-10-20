import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/audio_source_address.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// 基于just_audio的音频播放服务实现
class JustAudioPlayerService implements AudioPlayerService {
  AudioPlayer? _audioPlayer;

  /// 广播控制器：把 just_audio 的错误事件转成应用层错误。
  ///
  /// 控制器在字段初始化时创建，避免每次读取 [errorStream] 都新建一个
  /// 无人监听的流。
  final StreamController<AudioPlayerError> _errorController =
      StreamController<AudioPlayerError>.broadcast();

  StreamSubscription<PlayerException>? _errorSubscription;

  /// 初始化服务
  @override
  Future<void> init() async {
    try {
      // Linux 上 just_audio 没有官方实现，使用 media_kit（libmpv）作为后端
      if (Platform.isLinux) {
        JustAudioMediaKit.title = 'Tune';
        JustAudioMediaKit.ensureInitialized(linux: true, windows: false);
        Log.info('已注册 Linux 音频后端 (just_audio_media_kit)');
      }

      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );
      _audioPlayer = AudioPlayer();
      _listenForErrors(_audioPlayer!);
      Log.info('音频播放器初始化完成，已配置媒体会话');
    } catch (e, stackTrace) {
      Log.error('初始化音频播放器失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// 把播放后端的错误事件转发给上层。
  void _listenForErrors(AudioPlayer player) {
    _errorSubscription?.cancel();
    _errorSubscription = player.errorStream.listen((error) {
      Log.error('播放后端报错: $error');
      if (_errorController.isClosed) return;
      _errorController.add(
        AudioPlayerError(
          // The message of the backend is written in the language of the
          // backend, so the reader gets the one of the interface instead.
          message: AppStrings.instance.audioLoadFailed,
          code: error.code,
        ),
      );
    });
  }

  @override
  Future<void> play(Song song, {String? localFilePath}) async {
    try {
      // 确保播放器已初始化
      if (_audioPlayer == null) {
        await init();
      }

      // 本地副本优先；没有副本时才回退到歌曲自身的地址。
      final stored = localFilePath != null && localFilePath.isNotEmpty
          ? localFilePath
          : null;
      final String address = stored ?? song.playbackUri;

      // 检查音频路径是否为空
      if (address.isEmpty) {
        final message = AppStrings.instance.audioPathEmpty;
        Log.error(message);
        throw Exception(message);
      }

      Log.info('尝试播放音频: $address');

      // 释放之前的音频源以节省内存
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        final source = _sourceFor(song, address, fromStore: stored != null);
        await _audioPlayer!.setAudioSource(source);
        await _audioPlayer!.play();
      }
      Log.info('音频播放成功');
    } catch (e, stackTrace) {
      Log.error('播放音频失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// The source the backend loads.
  ///
  /// A stored copy is a file on the disk, and the address of the track itself
  /// is a network address for a remote track and a path for a local one.
  AudioSource _sourceFor(Song song, String address, {required bool fromStore}) {
    final uri = audioSourceAddress(song, address, fromStore: fromStore);
    final isNetwork = !fromStore && song.isRemote;
    return AudioSource.uri(uri, headers: isNetwork ? song.httpHeaders : null);
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
  Stream<Duration> get positionStream =>
      _audioPlayer?.positionStream ?? const Stream<Duration>.empty();

  @override
  Stream<Duration?> get durationStream =>
      _audioPlayer?.durationStream ?? const Stream<Duration?>.empty();

  @override
  Stream<bool> get playingStream =>
      _audioPlayer?.playingStream ?? const Stream<bool>.empty();

  @override
  Stream<void> get completionStream {
    final player = _audioPlayer;
    if (player == null) return const Stream<void>.empty();
    return player.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .map((_) {});
  }

  @override
  Stream<AudioPlayerError> get errorStream => _errorController.stream;

  @override
  void dispose() {
    try {
      _errorSubscription?.cancel();
      _errorSubscription = null;
      if (!_errorController.isClosed) {
        _errorController.close();
      }
      _audioPlayer?.dispose();
      _audioPlayer = null;
      Log.info('音频播放器资源释放成功');
    } catch (e, stackTrace) {
      Log.error('释放音频播放器资源失败: $e\nStack trace: $stackTrace');
    }
  }
}
