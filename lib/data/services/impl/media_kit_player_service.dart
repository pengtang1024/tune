import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/audio_source_address.dart';
import 'package:tune/data/services/mpv_policy.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// 桌面端（Linux / Windows）的播放后端：直接持有 media_kit 的 [Player]。
///
/// 为什么不用 `just_audio` + `just_audio_media_kit`：
///
/// 那两层能给的旋钮比 mpv 少一层。`just_audio` 的 `AudioPlayer` 没有暴露底层
/// 播放器，`just_audio_media_kit` 又把 media_kit 的 [Player] 与属性设置都藏在
/// 私有字段里——于是「缓存放哪、留不留磁盘副本」这类决定被迫沿用别人的默认值
/// （media_kit 硬开 `cache-on-disk=yes`，mpv 0.41 的缓存目录默认空串，于是每个
/// 流都建不出缓存文件）。这里直接对接 media_kit：缓存策略由 [MpvPolicy] 声明、
/// 在 [init] 里逐条落到 mpv 上，桌面端不再经过那两层适配。
///
/// 移动端仍用 `just_audio`（[JustAudioPlayerService]）：那里需要的是平台自带的
/// 音频焦点与 audio_service 的会话集成，media_kit 在 Android 上要接的东西更多。
class MediaKitAudioPlayerService implements AudioPlayerService {
  MediaKitAudioPlayerService({this.policy = const MpvPolicy()});

  /// 缓存策略。默认只留内存缓存，理由见 [MpvPolicy] 的说明。
  final MpvPolicy policy;

  Player? _player;

  /// 广播控制器：把 mpv 的错误事件转成应用层错误。
  ///
  /// 在字段初始化时创建，避免每次读取 [errorStream] 都新建一个无人监听的流。
  final StreamController<AudioPlayerError> _errorController =
      StreamController<AudioPlayerError>.broadcast();

  StreamSubscription<String>? _errorSubscription;

  @override
  Future<void> init() async {
    try {
      MediaKit.ensureInitialized();
      // 缓冲额度与标题走 PlayerConfiguration：media_kit 会把它翻译成
      // demuxer-max-bytes / demuxer-max-back-bytes，和 [MpvPolicy] 同源。
      // 日志级别留在 error：warning 级会淹没播放失败的真正原因。
      final player = Player(
        configuration: PlayerConfiguration(
          title: 'Tune',
          bufferSize: policy.bufferBytes,
          logLevel: MPVLogLevel.error,
        ),
      );
      _player = player;
      await _applyPolicy(player);
      _listenForErrors(player);
      Log.debug('音频播放后端已就绪 (media_kit / libmpv)');
    } catch (e, stackTrace) {
      Log.error('初始化音频播放器失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  /// 把 [policy] 落到 mpv 上。
  ///
  /// 直接改 mpv 属性要经过 [NativePlayer]，这是 media_kit 没有做成公开配置对象
  /// 的那一层。集中在这一个方法里，是为了让「碰底层」的位置只有一处。
  Future<void> _applyPolicy(Player player) async {
    final native = player.platform;
    if (native is! NativePlayer) {
      // 非原生后端（Web 等）：没有 mpv 属性可设，缓存策略自然不适用。
      Log.debug('当前后端不是 libmpv，跳过缓存策略');
      return;
    }
    for (final entry in policy.toProperties().entries) {
      await native.setProperty(entry.key, entry.value);
    }
    Log.debug(
      '已应用 mpv 缓存策略: 内存 ${policy.bufferBytes ~/ (1024 * 1024)} MiB，'
      '磁盘缓存${policy.usesDiskCache ? '开（${policy.diskCacheDirectory}）' : '关'}',
    );
  }

  /// 把 mpv 的错误事件转发给上层。
  void _listenForErrors(Player player) {
    _errorSubscription?.cancel();
    _errorSubscription = player.stream.error.listen((error) {
      Log.error('播放后端报错: $error');
      if (_errorController.isClosed) return;
      _errorController.add(
        AudioPlayerError(
          // mpv 的消息是 mpv 的语言，读者拿到的是界面语言的那一句。
          message: AppStrings.instance.audioLoadFailed,
        ),
      );
    });
  }

  @override
  Future<void> play(Song song, {String? localFilePath}) async {
    try {
      if (_player == null) await init();
      final player = _player;
      if (player == null) return;

      // 本地副本优先；没有副本时才回退到歌曲自身的地址。
      final stored =
          localFilePath != null && localFilePath.isNotEmpty ? localFilePath : null;
      final String address = stored ?? song.playbackUri;
      if (address.isEmpty) {
        final message = AppStrings.instance.audioPathEmpty;
        Log.error(message);
        throw Exception(message);
      }

      Log.debug('尝试播放音频: $address');
      await player.stop();
      final uri = audioSourceAddress(song, address, fromStore: stored != null);
      final isNetwork = stored == null && song.isRemote;
      await player.open(
        Media(
          uri.toString(),
          httpHeaders: isNetwork ? song.httpHeaders : null,
        ),
        // 这一首播不播是调用方的意思，默认就播——`open` 会等到加载完成再返回，
        // 不会像 just_audio 的 `play()` 那样等整首播完。
        play: true,
      );
      Log.debug('音频播放成功');
    } catch (e, stackTrace) {
      Log.error('播放音频失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (e, stackTrace) {
      Log.error('暂停播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _player?.play();
    } catch (e, stackTrace) {
      Log.error('恢复播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e, stackTrace) {
      Log.error('停止播放失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    try {
      await _player?.seek(position);
    } catch (e, stackTrace) {
      Log.error('跳转到指定位置失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      // 界面用 0.0–1.0，mpv 用 0–100，换算在这一层收口。
      final clamped = volume.clamp(0.0, 1.0);
      await _player?.setVolume(clamped * 100);
    } catch (e, stackTrace) {
      Log.error('设置音量失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      // 限制播放速度范围在 0.25 到 2.0 之间，与移动端一致。
      final clamped = speed.clamp(0.25, 2.0);
      await _player?.setRate(clamped);
    } catch (e, stackTrace) {
      Log.error('设置播放速度失败: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Duration get currentPosition {
    try {
      return _player?.state.position ?? Duration.zero;
    } catch (e, stackTrace) {
      Log.error('获取当前播放位置失败: $e\nStack trace: $stackTrace');
      return Duration.zero;
    }
  }

  @override
  Duration get duration {
    try {
      return _player?.state.duration ?? Duration.zero;
    } catch (e, stackTrace) {
      Log.error('获取音频时长失败: $e\nStack trace: $stackTrace');
      return Duration.zero;
    }
  }

  @override
  bool get isPlaying {
    try {
      return _player?.state.playing ?? false;
    } catch (e, stackTrace) {
      Log.error('获取播放状态失败: $e\nStack trace: $stackTrace');
      return false;
    }
  }

  @override
  double get speed {
    try {
      return _player?.state.rate ?? 1.0;
    } catch (e, stackTrace) {
      Log.error('获取播放速度失败: $e\nStack trace: $stackTrace');
      return 1.0;
    }
  }

  @override
  Stream<Duration> get positionStream =>
      _player?.stream.position ?? const Stream<Duration>.empty();

  @override
  Stream<Duration?> get durationStream =>
      _player?.stream.duration ?? const Stream<Duration?>.empty();

  @override
  Stream<bool> get playingStream =>
      _player?.stream.playing ?? const Stream<bool>.empty();

  @override
  Stream<void> get completionStream {
    final player = _player;
    if (player == null) return const Stream<void>.empty();
    // mpv 的 completed 在换曲时也会发一次 false，只取 true 的那一次。
    return player.stream.completed.where((completed) => completed).map((_) {});
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
      _player?.dispose();
      _player = null;
      Log.debug('音频播放器资源释放成功');
    } catch (e, stackTrace) {
      Log.error('释放音频播放器资源失败: $e\nStack trace: $stackTrace');
    }
  }
}
