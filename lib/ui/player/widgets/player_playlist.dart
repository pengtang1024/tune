import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

/// 播放列表组件
class PlayerPlaylist extends ConsumerWidget {
  const PlayerPlaylist({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    if (playerState.currentSong == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '播放列表',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: playerNotifier.getPlaylist().length,
              itemBuilder: (context, index) {
                final song = playerNotifier.getPlaylist()[index];
                final isCurrent = song.id == playerState.currentSong?.id;
                
                return ListTile(
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '${song.artist} - ${song.album}',
                    style: TextStyle(
                      color: isCurrent 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => playerNotifier.playSongAtIndex(index),
                  selected: isCurrent,
                  selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}