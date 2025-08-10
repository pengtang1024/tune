import 'package:tune/domain/entities/song.dart';

/// 桌面端音频播放（dart_vlc）
class AudioPlayerDesktop {
  /// 播放歌曲
  Future<void> play(Song song) async {
    // 使用dart_vlc播放歌曲
    // TODO: 实现dart_vlc播放逻辑
  }

  /// 暂停播放
  Future<void> pause() async {
    // 使用dart_vlc暂停播放
    // TODO: 实现dart_vlc暂停逻辑
  }

  /// 停止播放
  Future<void> stop() async {
    // 使用dart_vlc停止播放
    // TODO: 实现dart_vlc停止逻辑
  }
}