import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommended_track.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';

/// The wide card at the top of the discover page.
///
/// The card stands for the whole mix, not for one track: it shows the first
/// covers, says how many tracks are inside, and starts or queues them.
class DailyMixCard extends StatelessWidget {
  final DiscoverySection section;
  final VoidCallback onPlay;
  final VoidCallback onAddAll;

  const DailyMixCard({
    super.key,
    required this.section,
    required this.onPlay,
    required this.onAddAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracks = section.tracks;

    return Container(
      key: const ValueKey('discovery-daily-mix'),
      padding: const EdgeInsets.all(CompactTokens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Collage(tracks: tracks),
          const SizedBox(width: CompactTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.discoverSectionDailyMix,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.loc.discoverDailyMixSubtitle(tracks.length),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: CompactTokens.space12),
                Wrap(
                  spacing: CompactTokens.space8,
                  runSpacing: CompactTokens.space8,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('discovery-daily-play'),
                      onPressed: tracks.isEmpty ? null : onPlay,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(
                          0,
                          CompactTokens.controlDefault,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: CompactTokens.space12,
                        ),
                      ),
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        size: CompactTokens.icon16,
                      ),
                      label: Text(context.loc.discoverPlay),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('discovery-daily-queue'),
                      onPressed: tracks.isEmpty ? null : onAddAll,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          0,
                          CompactTokens.controlDefault,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: CompactTokens.space12,
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      icon: const Icon(
                        Icons.playlist_add_rounded,
                        size: CompactTokens.icon16,
                      ),
                      label: Text(context.loc.discoverAddAllShort),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Collage extends StatelessWidget {
  final List<RecommendedTrack> tracks;

  const _Collage({required this.tracks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      height: 120,
      child: Wrap(
        spacing: CompactTokens.space4,
        runSpacing: CompactTokens.space4,
        children: [
          for (var index = 0; index < 4; index++)
            if (index < tracks.length)
              ArtworkThumb(
                path: tracks[index].song.albumArtPath,
                imageUrl: tracks[index].song.artworkUrl,
                size: 58,
                radius: CompactTokens.radius8,
              )
            else
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(CompactTokens.radius8),
                ),
              ),
        ],
      ),
    );
  }
}
