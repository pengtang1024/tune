import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/widgets/player_speed.dart';
import 'package:tune/ui/player/widgets/player_volume.dart';

/// 播放器底部选项区域
class PlayerOptions extends ConsumerWidget {
  const PlayerOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          PlayerVolume(),
          PlayerSpeed(),
        ],
      ),
    );
  }
}