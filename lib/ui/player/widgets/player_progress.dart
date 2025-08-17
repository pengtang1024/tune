import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

/// 播放进度条组件
class PlayerProgress extends ConsumerWidget {
  const PlayerProgress({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Column(
      children: [
        Slider(
          value: playerState.duration.inMilliseconds == 0
              ? 0
              : (playerState.position.inMilliseconds / playerState.duration.inMilliseconds)
                  .clamp(0.0, 1.0)
                  .toDouble(),
          onChanged: (value) {
            final newPosition =
                Duration(milliseconds: (playerState.duration.inMilliseconds * value).toInt());
            playerNotifier.seekTo(newPosition);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(playerState.position)),
              Text(_formatDuration(playerState.duration)),
            ],
          ),
        ),
      ],
    );
  }
}