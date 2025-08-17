import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/impl/just_audio_player_service.dart';

/// AudioPlayerService提供者
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return JustAudioPlayerService();
});