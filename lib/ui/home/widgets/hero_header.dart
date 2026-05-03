import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';
import 'package:go_router/go_router.dart';

class HeroHeader extends ConsumerWidget {
  const HeroHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildWelcomeSection(theme, isDark),
        if (playerState.currentSong != null) ...[
          const SizedBox(height: AppDesignSystem.spacing24),
          _buildMiniPlayer(context, ref, playerState.currentSong!),
        ],
      ],
    );
  }

  Widget _buildWelcomeSection(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Container(
          width: AppDesignSystem.albumCoverSize160,
          height: AppDesignSystem.albumCoverSize160,
          decoration: BoxDecoration(
            gradient: AppDesignSystem.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppDesignSystem.shadowColored,
          ),
          child: const Icon(
            Icons.music_note_rounded,
            size: AppDesignSystem.iconSize80,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing24),
        Text(
          '欢迎使用 Tune',
          style: AppDesignSystem.textTheme.headlineMedium?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
            color: isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        Text(
          '让每一段旋律都找到归属',
          style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPlayer(BuildContext context, WidgetRef ref, Song song) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final playerState = ref.watch(playerStateNotifierProvider);

    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      onTap: () => context.go('/player'),
      child: Row(
        children: [
          _buildAlbumArt(isDark),
          const SizedBox(width: AppDesignSystem.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: AppDesignSystem.textTheme.titleSmall?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightSemiBold,
                    color: isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  song.artist,
                  style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: AppDesignSystem.iconSize32,
            ),
            color: AppDesignSystem.primary,
            onPressed: () {
              if (playerState.isPlaying) {
                playerNotifier.pause();
              } else {
                playerNotifier.resume();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(bool isDark) {
    return Container(
      width: AppDesignSystem.albumCoverSize56,
      height: AppDesignSystem.albumCoverSize56,
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
        borderRadius: AppDesignSystem.borderRadius12,
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: AppDesignSystem.iconSize28,
      ),
    );
  }
}
