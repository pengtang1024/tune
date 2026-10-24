import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/presentation/discovery_reason_label.dart';
import 'package:tune/features/discovery/presentation/recommendation_card.dart';
import 'package:tune/shared/ui/source_label.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// One row of the discover page.
class DiscoverySectionView extends StatelessWidget {
  final DiscoverySection section;
  final Map<String, SourceLabel> sourceLabels;
  final Set<String> favoriteUris;
  final String? currentUri;
  final bool isPlaying;
  final bool waitsForDoubleClick;
  final ValueChanged<Song> onTap;
  final ValueChanged<Song> onDoubleTap;
  final ValueChanged<Song> onToggleFavorite;
  final ValueChanged<Song> onAddToQueue;
  final ValueChanged<Song> onDismiss;
  final ValueChanged<Song> onDetails;
  final VoidCallback onPlayAll;
  final VoidCallback onAddAll;

  const DiscoverySectionView({
    super.key,
    required this.section,
    required this.sourceLabels,
    required this.favoriteUris,
    required this.currentUri,
    required this.isPlaying,
    required this.waitsForDoubleClick,
    required this.onTap,
    required this.onDoubleTap,
    required this.onToggleFavorite,
    required this.onAddToQueue,
    required this.onDismiss,
    required this.onDetails,
    required this.onPlayAll,
    required this.onAddAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = discoverySectionTitle(context, section, sourceLabels);

    return Column(
      key: ValueKey('discovery-section-${section.kind.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.loc.libraryTrackCount(section.length),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TuneTooltip(
              message: context.loc.discoverPlayAll,
              child: IconButton(
                key: ValueKey('discovery-play-${section.kind.name}'),
                onPressed: section.tracks.isEmpty ? null : onPlayAll,
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: CompactTokens.icon18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            TuneTooltip(
              message: context.loc.discoverAddAllToQueue,
              child: IconButton(
                key: ValueKey('discovery-queue-${section.kind.name}'),
                onPressed: section.tracks.isEmpty ? null : onAddAll,
                icon: const Icon(
                  Icons.playlist_add_rounded,
                  size: CompactTokens.icon18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CompactTokens.space8),
        SizedBox(
          height: 236,
          child: ListView.separated(
            key: ValueKey('discovery-list-${section.kind.name}'),
            scrollDirection: Axis.horizontal,
            itemCount: section.tracks.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: CompactTokens.space10),
            itemBuilder: (context, index) {
              final track = section.tracks[index];
              final song = track.song;
              return RecommendationCard(
                key: ValueKey('discovery-card-${song.uri}'),
                track: track,
                source: sourceLabel(song, sourceLabels),
                isFavorite: favoriteUris.contains(song.uri),
                selected: currentUri == song.uri,
                playing: currentUri == song.uri && isPlaying,
                waitsForDoubleClick: waitsForDoubleClick,
                sourceLabels: sourceLabels,
                onTap: () => onTap(song),
                onDoubleTap: () => onDoubleTap(song),
                onToggleFavorite: () => onToggleFavorite(song),
                onAddToQueue: () => onAddToQueue(song),
                onDismiss: () => onDismiss(song),
                onDetails: () => onDetails(song),
              );
            },
          ),
        ),
      ],
    );
  }
}
