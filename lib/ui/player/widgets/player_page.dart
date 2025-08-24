import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/player_state_notifier.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/ui/player/widgets/player_controls.dart';
import 'package:tune/ui/player/widgets/player_progress.dart';
import 'package:tune/ui/player/widgets/player_speed.dart';
import 'package:tune/ui/player/widgets/player_volume.dart';
import 'package:tune/ui/player/widgets/player_playlist.dart';
import 'package:tune/ui/player/widgets/player_equalizer.dart';
import 'package:tune/ui/player/widgets/player_history.dart';

/// 播放器首页面
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final loc = context.loc;

    if (playerState.errorMessage.isNotEmpty) {
      return Center(
        child: Text('${loc.playback_error}: ${playerState.errorMessage}'), // 使用本地化字符串
      );
    }

    if (playerState.currentSong == null) {
      return Center(
        child: Text(
          '${loc.no_song_playing}\n${loc.select_a_song_to_play}', // 使用本地化字符串
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
              PlayerModeControls(playerNotifier: playerNotifier),
              const SizedBox(height: 32),

              // 均衡器控制
              const PlayerEqualizer(),
              const SizedBox(height: 32),

              // 播放历史记录
              const PlayerHistory(),
              const SizedBox(height: 32),

              // 播放列表
              const PlayerPlaylist(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// 播放模式控制组件
class PlayerModeControls extends ConsumerWidget {
  final PlayerStateNotifier playerNotifier;
  
  const PlayerModeControls({super.key, required this.playerNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
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