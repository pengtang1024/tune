import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/impl/just_audio_player_service.dart';
import 'package:tune/data/services/impl/media_kit_player_service.dart';

/// AudioPlayerService提供者
///
/// 桌面端用 media_kit 直连 libmpv 的后端（缓存策略由 `MpvPolicy` 决定），
/// 移动端仍用 just_audio（平台音频焦点与 audio_service 会话都在那边）。
/// 两套后端实现同一个接口，界面与播放控制不需要知道跑在哪一套上。
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = Platform.isLinux || Platform.isWindows
      ? MediaKitAudioPlayerService()
      : JustAudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});
