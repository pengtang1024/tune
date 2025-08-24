import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/ui/player/widgets/player_speed.dart';
import 'package:tune/ui/player/widgets/player_volume.dart';

/// 播放器主要内容区域
class PlayerContent extends ConsumerWidget {
  const PlayerContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 专辑封面
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.music_note,
                size: 100,
                color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 32),

          // 歌曲信息
          Text(
            playerState.currentSong?.title ?? '未知歌曲',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '${playerState.currentSong?.artist ?? '未知艺术家'} - ${playerState.currentSong?.album ?? '未知专辑'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 音量和速度控制
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: const [
              PlayerVolume(),
              PlayerSpeed(),
            ],
          ),
          const SizedBox(height: 16),

          // 播放模式控制
          PlayerModeControls(),
          const SizedBox(height: 32),
        ],
      ),
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
    final loc = context.loc;

    IconData getModeIcon() {
      switch (playerState.playMode) {
        case PlayMode.shuffle:
          return Icons.shuffle;
        case PlayMode.repeatOne:
          return Icons.repeat_one;
        default:
          return Icons.repeat;
      }
    }

    String getModeTooltip() {
      switch (playerState.playMode) {
        case PlayMode.shuffle:
          return loc.shuffle;
        case PlayMode.repeatOne:
          return loc.repeat_one;
        default:
          return loc.repeat_all;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 播放模式按钮
        IconButton(
          icon: Icon(getModeIcon()),
          color: Theme.of(context).colorScheme.primary,
          tooltip: getModeTooltip(),
          onPressed: playerNotifier.togglePlayMode,
        ),
      ],
    );
  }
}