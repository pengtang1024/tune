import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class PlayerPlaylist extends ConsumerWidget {
  const PlayerPlaylist({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (playerState.currentSong == null) {
      return const SizedBox.shrink();
    }

    final playlist = playerNotifier.getPlaylist();

    return Container(
      height: 200,
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
            context.loc.playlist,
            style: AppDesignSystem.textTheme.titleSmall?.copyWith(
              fontWeight: AppDesignSystem.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: playlist.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final item = playlist.removeAt(oldIndex);
                playlist.insert(newIndex, item);
              },
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.02,
                      child: Material(elevation: 4, borderRadius: AppDesignSystem.borderRadius8, child: child),
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final song = playlist[index];
                final isCurrent = song.id == playerState.currentSong?.id;

                return Dismissible(
                  key: ValueKey(song.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (dir) async {
                    ref.read(playerStateNotifierProvider.notifier).removeFromPlaylist(song);
                    return true;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppDesignSystem.spacing20),
                    color: AppDesignSystem.error.withValues(alpha: 0.8),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: AppInteractions.clickableCard(
                  borderRadius: AppDesignSystem.borderRadius8,
                  onTap: () => playerNotifier.playSongAtIndex(index),
                  child: AnimatedContainer(
                    duration: AppDesignSystem.duration200,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spacing12,
                      vertical: AppDesignSystem.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppDesignSystem.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: AppDesignSystem.borderRadius8,
                      border: isCurrent
                          ? Border.all(color: AppDesignSystem.primary.withValues(alpha: 0.2))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrent ? Icons.play_circle_filled : Icons.music_note,
                          size: AppDesignSystem.iconSize20,
                          color: isCurrent
                              ? AppDesignSystem.primary
                              : (isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600),
                        ),
                        const SizedBox(width: AppDesignSystem.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isCurrent
                                      ? AppDesignSystem.fontWeightSemiBold
                                      : AppDesignSystem.fontWeightNormal,
                                  color: isCurrent ? AppDesignSystem.primary : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                                  color: isCurrent
                                      ? AppDesignSystem.primary.withValues(alpha: 0.7)
                                      : AppDesignSystem.neutral500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
