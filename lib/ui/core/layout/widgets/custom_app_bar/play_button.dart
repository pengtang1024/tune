import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

class PlayButton extends ConsumerWidget {
  const PlayButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);

    Widget getPlayIcon() {
      if (appBarState.isPlayButtonHovered) {
        if (playerState.isPlaying) {
          return const Icon(Icons.pause);
        } else {
          return const Icon(Icons.play_arrow);
        }
      } else {
        if (playerState.isPlaying) {
          return const Icon(Icons.pause);
        } else {
          return const Icon(Icons.play_arrow);
        }
      }
    }

    return MouseRegion(
      onEnter: (_) {
        appBarNotifier.setPlayButtonHover(true);
      },
      onExit: (_) {
        appBarNotifier.setPlayButtonHover(false);
      },
      child: GestureDetector(
        onLongPress: () {
          playerNotifier.stop();
        },
        child: IconButton(
          icon: getPlayIcon(),
          tooltip: playerState.isPlaying ? '暂停' : '播放',
          onPressed: () {
            if (playerState.isPlaying) {
              playerNotifier.pause();
            } else {
              playerNotifier.play();
            }
          },
        ),
      ),
    );
  }
}
