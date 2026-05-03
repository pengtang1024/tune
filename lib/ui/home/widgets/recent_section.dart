import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

/// 最近播放组件
/// 展示最近播放的歌曲列表
class RecentSection extends ConsumerWidget {
  const RecentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    // 获取播放历史
    final playerNotifier = ref.watch(playerStateNotifierProvider.notifier);
    // 从播放器状态中获取最近播放的歌曲
    final List<Song> songs = playerNotifier.getPlayHistory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.recently_played,
              style: AppDesignSystem.textTheme.titleLarge?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightBold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // 导航到历史记录页面
                context.go('/history');
              },
              child: Text(
                loc.see_all,
                style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                  color: AppDesignSystem.primary,
                  fontWeight: AppDesignSystem.fontWeightMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesignSystem.spacing12),
        if (songs.isEmpty) ...[
          ModernCard(
            padding: const EdgeInsets.all(AppDesignSystem.spacing24),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: AppDesignSystem.iconSize64,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppDesignSystem.spacing16),
                Text(
                  loc.no_recent_songs,
                  style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: songs.take(3).map((song) {
                return MusicCardWidget(
                  song: song,
                  onTap: () {
                    // 播放歌曲
                    // 设置播放列表并播放选中的歌曲
                    final index = songs.indexOf(song);
                    playerNotifier.setPlaylist(songs, startIndex: index);
                    playerNotifier.playSong(song);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class MusicCardWidget extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const MusicCardWidget({super.key, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppDesignSystem.primaryGradient,
                  borderRadius: AppDesignSystem.borderRadius12,
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: AppDesignSystem.iconSize24,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                        fontWeight: AppDesignSystem.fontWeightMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${song.artist} - ${song.album}',
                      style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Text(
                _formatDuration(song.duration),
                style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int durationInSeconds) {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}