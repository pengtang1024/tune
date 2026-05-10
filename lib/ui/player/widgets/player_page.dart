import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/widgets/player_content.dart';
import 'package:tune/ui/player/widgets/player_controls.dart';
import 'package:tune/ui/player/widgets/player_history.dart';
import 'package:tune/ui/player/widgets/player_options.dart';
import 'package:tune/ui/player/widgets/player_progress.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < AppDesignSystem.breakpointMobile;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0F0F),
                  Color(0xFF1A1A1A),
                  Color(0xFF2D1B69),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                  Color(0xFFE0E7FF),
                ],
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(context, playerState, isCompact),
            if (playerState.isError)
              _buildErrorCard(context, ref, playerState),
            Expanded(
              child: playerState.isLoading || playerState.isError
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResponsiveContent(context, isCompact),
            ),
            if (!playerState.isLoading && !playerState.isError) ...[
              const SizedBox(height: AppDesignSystem.spacing12),
              const PlayerProgress(),
              const SizedBox(height: AppDesignSystem.spacing16),
              const PlayerControls(),
              const SizedBox(height: AppDesignSystem.spacing16),
              if (!isCompact) ...[
                const PlayerOptions(),
                const SizedBox(height: AppDesignSystem.spacing12),
                const PlayerHistory(),
              ],
              SizedBox(height: isCompact ? AppDesignSystem.spacing16 : AppDesignSystem.spacing12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(BuildContext context, bool isCompact) {
    if (isCompact) {
      return const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
        child: PlayerContent(),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing24,
            ),
            child: const PlayerContent(),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing16,
            ),
            child: Column(
              children: const [
                SizedBox(height: AppDesignSystem.spacing24),
                PlayerOptions(),
                SizedBox(height: AppDesignSystem.spacing16),
                PlayerHistory(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAppBar(BuildContext context, dynamic playerState, bool isCompact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(isCompact ? AppDesignSystem.spacing12 : AppDesignSystem.spacing16),
      child: Row(
        children: [
          AppInteractions.pressableScale(
            onTap: () => context.pop(),
            scaleValue: 0.92,
            child: ModernCard(
              padding: const EdgeInsets.all(AppDesignSystem.spacing8),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppDesignSystem.iconSize28,
              ),
            ),
          ),
          if (playerState.currentSong != null) ...[
            const Spacer(),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    playerState.currentSong!.title,
                    style: AppDesignSystem.textTheme.titleMedium?.copyWith(
                      fontWeight: AppDesignSystem.fontWeightSemiBold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDesignSystem.spacing4),
                  Text(
                    playerState.currentSong!.artist,
                    style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppDesignSystem.neutral400
                          : AppDesignSystem.neutral600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Spacer(),
          ] else ...[
            const Spacer(),
          ],
          AppInteractions.pressableScale(
            scaleValue: 0.92,
            child: ModernCard(
              padding: const EdgeInsets.all(AppDesignSystem.spacing8),
              child: const Icon(
                Icons.more_vert_rounded,
                size: AppDesignSystem.iconSize28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, dynamic playerState) {
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing16,
        vertical: AppDesignSystem.spacing8,
      ),
      child: ModernCard(
        backgroundColor: AppDesignSystem.error.withValues(alpha: 0.1),
        borderSide: BorderSide(color: AppDesignSystem.error.withValues(alpha: 0.3)),
        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.error_rounded, color: AppDesignSystem.error, size: AppDesignSystem.iconSize24),
                const SizedBox(width: AppDesignSystem.spacing12),
                Expanded(
                  child: Text(
                    '播放错误',
                    style: AppDesignSystem.textTheme.titleMedium?.copyWith(
                      color: AppDesignSystem.error,
                      fontWeight: AppDesignSystem.fontWeightSemiBold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDesignSystem.spacing8),
            Text(
              playerState.errorMessage,
              style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                color: AppDesignSystem.error,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            SizedBox(
              width: double.infinity,
              child: AppInteractions.pressableScale(
                onTap: () {
                  if (playerState.currentSong != null) {
                    playerNotifier.playSong(playerState.currentSong!);
                  }
                },
                child: ModernCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing24,
                    vertical: AppDesignSystem.spacing12,
                  ),
                  backgroundColor: AppDesignSystem.error,
                  child: Text(
                    '重试',
                    style: AppDesignSystem.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: AppDesignSystem.fontWeightSemiBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
