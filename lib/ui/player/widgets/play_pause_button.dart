import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

class PlayPauseButton extends ConsumerWidget {
  const PlayPauseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return FloatingActionButton(
      onPressed: playerState.currentSong != null
          ? (playerState.isPlaying ? playerNotifier.pause : playerNotifier.play)
          : null,
      child: Icon(
        playerState.isPlaying ? Icons.pause : Icons.play_arrow,
        size: 48.0,
      ),
    );
  }
}
