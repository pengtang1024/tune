import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/widgets/player_controls.dart';
import 'package:tune/ui/player/widgets/player_progress.dart';

/// 播放器首页面
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final localizations = context.loc;

    if (playerState.errorMessage.isNotEmpty) {
      return Center(
        child: Text('${localizations.playback_error}: ${playerState.errorMessage}'), // 使用本地化字符串
      );
    }

    if (playerState.currentSong == null) {
      return Center(
        child: Text(
          '${localizations.no_song_playing}\n${localizations.select_a_song_to_play}', // 使用本地化字符串
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 专辑封面占位符
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.music_note, size: 100, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 32),

            // 歌曲信息
            Text(
              playerState.currentSong!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '${playerState.currentSong!.artist} - ${playerState.currentSong!.album}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
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
            const PlayerVolume(),

            // 播放模式控制
            const PlayerModeControls(),
          ],
        ),
      ),
    );
  }
}

/// 音量控制组件
class PlayerVolume extends ConsumerWidget {
  const PlayerVolume({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Row(
      children: [
        const Icon(Icons.volume_down),
        Expanded(
          child: Slider(value: playerState.volume, onChanged: playerNotifier.setVolume),
        ),
        const Icon(Icons.volume_up),
      ],
    );
  }
}

/// 播放模式控制组件
class PlayerModeControls extends ConsumerWidget {
  const PlayerModeControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 随机播放按钮
        IconButton(
          icon: Icon(playerState.isShuffleMode ? Icons.shuffle : Icons.shuffle_outlined, color: playerState.isShuffleMode ? Theme.of(context).colorScheme.primary : null),
          onPressed: playerNotifier.toggleShuffleMode,
        ),

        // 循环播放按钮
        IconButton(
          icon: const Icon(Icons.repeat),
          onPressed: () {
            // TODO: 实现循环播放模式切换
          },
        ),
      ],
    );
  }
}
