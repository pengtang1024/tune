import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 迷你播放器组件
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    if (playerState.currentSong == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: AppDesignSystem.shadowSmall,
      ),
      child: Row(
        children: [
          // 专辑封面
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppDesignSystem.primaryGradient,
              boxShadow: AppDesignSystem.shadowColored,
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: AppDesignSystem.iconSize32,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),

          // 歌曲信息
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerState.currentSong!.title,
                  style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightSemiBold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${playerState.currentSong!.artist} - ${playerState.currentSong!.album}',
                  style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing8),

          // 控制按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: AppDesignSystem.iconSize28,
                ),
                color: AppDesignSystem.primary,
                onPressed: playerState.isPlaying
                    ? playerNotifier.pause
                    : playerNotifier.play,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: AppDesignSystem.iconSize24),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                onPressed: playerNotifier.next,
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: AppDesignSystem.iconSize24),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                onPressed: () => context.push('/player'),
              ),
            ],
          ),
          const SizedBox(width: AppDesignSystem.spacing8),
        ],
      ),
    );
  }
}
