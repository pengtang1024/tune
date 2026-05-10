import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';
import 'package:tune/ui/widgets/modern_button.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class WelcomeSection extends ConsumerWidget {
  final PlayerState playerState;
  const WelcomeSection({super.key, required this.playerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final now = DateTime.now();
    String greeting;
    if (now.hour < 12) {
      greeting = loc.good_morning;
    } else if (now.hour < 18) {
      greeting = loc.good_afternoon;
    } else {
      greeting = loc.good_evening;
    }

    return ModernCard(
      padding: const EdgeInsets.fromLTRB(AppDesignSystem.spacing20, AppDesignSystem.spacing20, AppDesignSystem.spacing20, AppDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,\n${loc.welcome_to_tune}',
            style: AppDesignSystem.textTheme.headlineMedium?.copyWith(
              fontWeight: AppDesignSystem.fontWeightBold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          if (playerState.currentSong != null) ...[
            Text(
              loc.now_playing,
              style: AppDesignSystem.textTheme.titleMedium?.copyWith(color: AppDesignSystem.primary),
            ),
            const SizedBox(height: AppDesignSystem.spacing8),
            _NowPlayingRow(song: playerState.currentSong!, isPlaying: playerState.isPlaying),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing16),
              decoration: BoxDecoration(
                color: AppDesignSystem.primary.withValues(alpha: 0.08),
                borderRadius: AppDesignSystem.borderRadius12,
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note, size: AppDesignSystem.iconSize32, color: AppDesignSystem.primary),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: Text(
                      loc.no_song_playing,
                      style: AppDesignSystem.textTheme.bodyMedium?.copyWith(color: AppDesignSystem.primary),
                    ),
                  ),
                  ModernButton.text(
                    text: loc.scan_local_music,
                    onPressed: () => context.go('/scan'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NowPlayingRow extends ConsumerWidget {
  final dynamic song;
  final bool isPlaying;
  const _NowPlayingRow({required this.song, required this.isPlaying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: AppDesignSystem.primaryGradient,
            borderRadius: AppDesignSystem.borderRadius12,
          ),
          child: const Icon(Icons.music_note_rounded, color: Colors.white, size: AppDesignSystem.iconSize28),
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.title, style: AppDesignSystem.textTheme.titleSmall?.copyWith(fontWeight: AppDesignSystem.fontWeightSemiBold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${song.artist} - ${song.album}', style: AppDesignSystem.textTheme.bodySmall?.copyWith(color: AppDesignSystem.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        AppInteractions.pressableScale(
          scaleValue: 0.9,
          onTap: () => isPlaying ? playerNotifier.pause() : playerNotifier.play(),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppDesignSystem.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppDesignSystem.primary, size: AppDesignSystem.iconSize28,
            ),
          ),
        ),
      ],
    );
  }
}
