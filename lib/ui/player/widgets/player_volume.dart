import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

/// 音量控制组件
class PlayerVolume extends ConsumerWidget {
  const PlayerVolume({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.volume_down),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Slider(
            value: playerState.volume,
            onChanged: playerNotifier.setVolume,
          ),
        ),
        const Icon(Icons.volume_up),
      ],
    );
  }
}