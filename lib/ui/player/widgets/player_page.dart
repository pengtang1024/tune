import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/providers/app_bar_providers.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/widgets/player_controls.dart';
import 'package:tune/ui/player/widgets/player_progress.dart';

/// 播放器主页面
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final appBarState = ref.watch(appBarStateNotifierProvider);

    // 更新AppBar状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
      appBarNotifier.updateAppBar('播放器', false);
    });

    if (playerState.errorMessage.isNotEmpty) {
      return Center(
        child: Text('播放出错: ${playerState.errorMessage}'),
      );
    }

    if (playerState.currentSong == null) {
      return const Center(
        child: Text(
          '暂无播放歌曲\n请选择一首歌曲开始播放',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarState.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 专辑封面占位符
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.music_note,
                size: 100,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            
            // 歌曲信息
            Text(
              playerState.currentSong!.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${playerState.currentSong!.artist ?? '未知艺术家'} · ${playerState.currentSong!.album ?? '未知专辑'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // 播放进度
            const PlayerProgress(),
            const SizedBox(height: 32),
            
            // 播放控制
            const PlayerControls(),
            const SizedBox(height: 32),
            
            // 音量控制
            const VolumeControl(),
          ],
        ),
      ),
    );
  }
}

/// 音量控制组件
class VolumeControl extends ConsumerWidget {
  const VolumeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Row(
      children: [
        const Icon(Icons.volume_down),
        Expanded(
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