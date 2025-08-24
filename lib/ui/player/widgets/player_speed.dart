import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

/// 播放速度控制组件
class PlayerSpeed extends ConsumerWidget {
  const PlayerSpeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final loc = context.loc;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.speed),
          onPressed: null,
          tooltip: loc.playback_speed,
        ),
        DropdownButton<double>(
          value: playerState.speed,
          items: [
            DropdownMenuItem(value: 0.5, child: Text('0.5x')),
            DropdownMenuItem(value: 0.75, child: Text('0.75x')),
            DropdownMenuItem(value: 1.0, child: Text('1.0x')),
            DropdownMenuItem(value: 1.25, child: Text('1.25x')),
            DropdownMenuItem(value: 1.5, child: Text('1.5x')),
            DropdownMenuItem(value: 2.0, child: Text('2.0x')),
          ],
          onChanged: (value) {
            if (value != null) {
              playerNotifier.setSpeed(value);
            }
          },
        ),
      ],
    );
  }
}