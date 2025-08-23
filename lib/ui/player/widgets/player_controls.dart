import 'package:tune/ui/player/widgets/play_pause_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 48.0,
          onPressed: playerState.currentSong != null ? playerNotifier.previous : null,
        ),
        const SizedBox(width: 16.0),
        const PlayPauseButton(),
        const SizedBox(width: 16.0),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 48.0,
          onPressed: playerState.currentSong != null ? playerNotifier.next : null,
        ),
      ],
    );
  }
}