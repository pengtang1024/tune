import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class PlayerHistory extends ConsumerWidget {
  const PlayerHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final loc = context.loc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Song> history = playerNotifier.getPlayHistory().take(5).toList();

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignSystem.neutral900.withValues(alpha: 0.6)
            : AppDesignSystem.neutral100.withValues(alpha: 0.6),
        borderRadius: AppDesignSystem.borderRadius16,
        border: Border.all(
          color: isDark ? AppDesignSystem.neutral800 : AppDesignSystem.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.recently_played,
            style: AppDesignSystem.textTheme.titleSmall?.copyWith(
              fontWeight: AppDesignSystem.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final song = history[index];
                return _HistorySongCard(song: song);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySongCard extends ConsumerWidget {
  final Song song;
  const _HistorySongCard({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: AppDesignSystem.spacing10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppDesignSystem.borderRadius12,
        boxShadow: [AppDesignSystem.shadowLight.first],
      ),
      child: AppInteractions.clickableCard(
        borderRadius: AppDesignSystem.borderRadius12,
        onTap: () => playerNotifier.playSong(song),
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacing10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppDesignSystem.primaryGradient,
                  borderRadius: AppDesignSystem.borderRadius24,
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: Colors.white, size: AppDesignSystem.iconSize20),
              ),
              const SizedBox(height: AppDesignSystem.spacing4),
              Text(
                song.title,
                style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                  fontWeight: AppDesignSystem.fontWeightMedium,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                song.artist,
                style: AppDesignSystem.textTheme.labelSmall?.copyWith(
                  color: AppDesignSystem.neutral500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
