import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

/// 欢迎区域组件
/// 展示欢迎信息和当前播放状态
class WelcomeSection extends ConsumerWidget {
  final PlayerState playerState;

  const WelcomeSection({super.key, required this.playerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final currentTime = DateTime.now();
    String greeting;
    
    if (currentTime.hour < 12) {
      greeting = loc.good_morning;
    } else if (currentTime.hour < 18) {
      greeting = loc.good_afternoon;
    } else {
      greeting = loc.good_evening;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,\n${loc.welcome_to_tune}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (playerState.currentSong != null) ...[
              Text(
                loc.now_playing,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    image: playerState.currentSong?.albumArt != null 
                      ? DecorationImage(
                          image: NetworkImage(playerState.currentSong!.albumArt!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  ),
                  child: playerState.currentSong?.albumArt == null
                      ? Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                title: Text(
                  playerState.currentSong!.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${playerState.currentSong!.artist} - ${playerState.currentSong!.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: Icon(
                      playerState.isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      // 切换播放状态
                      final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
                      if (playerState.isPlaying) {
                        playerNotifier.pause();
                      } else {
                        playerNotifier.play();
                      }
                    },
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.no_song_playing,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: 实现音乐扫描功能或添加路由
                        // context.router.push('/music-scan');
                      },
                      child: Text(loc.scan_local_music),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}