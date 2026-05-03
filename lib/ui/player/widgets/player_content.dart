import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/ui/player/widgets/player_speed.dart';
import 'package:tune/ui/player/widgets/player_volume.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class PlayerContent extends ConsumerWidget {
  const PlayerContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing16,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppDesignSystem.spacing24),
            // 专辑封面
            _AlbumArt(),
            const SizedBox(height: AppDesignSystem.spacing32),
            // 歌曲信息
            _SongInfo(
              title: playerState.currentSong?.title ?? '未知歌曲',
              artist: playerState.currentSong?.artist ?? '未知艺术家',
              album: playerState.currentSong?.album ?? '未知专辑',
            ),
            const SizedBox(height: AppDesignSystem.spacing32),
            // 音量和速度控制
            const _PlayerControlsRow(),
            const SizedBox(height: AppDesignSystem.spacing24),
            // 播放模式控制
            const _PlayModeControl(),
          ],
        ),
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDesignSystem.albumCoverSize240,
      height: AppDesignSystem.albumCoverSize240,
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
        borderRadius: AppDesignSystem.borderRadius24,
        boxShadow: AppDesignSystem.shadowColored,
      ),
      child: const Icon(
        Icons.music_note,
        size: AppDesignSystem.iconSize80,
        color: Colors.white,
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  final String title;
  final String artist;
  final String album;

  const _SongInfo({
    required this.title,
    required this.artist,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          title,
          style: AppDesignSystem.textTheme.headlineMedium?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        Text(
          '$artist - $album',
          style: AppDesignSystem.textTheme.titleMedium?.copyWith(
            color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PlayerControlsRow extends StatelessWidget {
  const _PlayerControlsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        PlayerVolume(),
        SizedBox(width: AppDesignSystem.spacing32),
        PlayerSpeed(),
      ],
    );
  }
}

class _PlayModeControl extends ConsumerWidget {
  const _PlayModeControl();

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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing20,
        vertical: AppDesignSystem.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppDesignSystem.primary.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadius16,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            getModeTooltip(),
            style: AppDesignSystem.textTheme.labelLarge?.copyWith(
              color: AppDesignSystem.primary,
              fontWeight: AppDesignSystem.fontWeightMedium,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          IconButton(
            icon: Icon(getModeIcon()),
            color: AppDesignSystem.primary,
            tooltip: getModeTooltip(),
            onPressed: playerNotifier.togglePlayMode,
          ),
        ],
      ),
    );
  }
}
