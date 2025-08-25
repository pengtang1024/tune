import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

/// 欢迎区域组件
/// 展示欢迎信息和当前播放状态
class WelcomeSection extends ConsumerWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final loc = context.loc;
    
    // 根据当前时间选择合适的问候语
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$greeting\n${loc.welcome_to_tune}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (playerState.currentSong != null) ...[
              Text(loc.now_playing, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                title: Text(playerState.currentSong?.title ?? ''),
                subtitle: Text('${playerState.currentSong?.artist ?? ''} - ${playerState.currentSong?.album ?? ''}'),
                trailing: IconButton(
                  icon: Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    // TODO: 切换播放状态
                  },
                ),
              ),
            ] else ...[
              Text(loc.no_song_playing, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
            ],
          ],
        ),
      ),
    );
  }
}