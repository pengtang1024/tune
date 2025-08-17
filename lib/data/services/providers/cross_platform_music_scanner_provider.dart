import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/impl/platform_music_service.dart';
import 'package:tune/providers/music_providers.dart';

/// CrossPlatformMusicScanner提供者
final crossPlatformMusicScannerProvider = Provider<CrossPlatformMusicScanner>((ref) {
  final musicService = ref.read(platformMusicServiceProvider);
  return CrossPlatformMusicScannerImpl(musicService);
});