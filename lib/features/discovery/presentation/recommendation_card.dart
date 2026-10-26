import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
import 'package:tune/features/discovery/domain/recommended_track.dart';
import 'package:tune/features/discovery/presentation/discovery_reason_label.dart';
import 'package:tune/features/discovery/presentation/recommendation_card_menu.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/track_click_area.dart';

class RecommendationCard extends StatelessWidget {
  /// The side of the cover of one card.
  ///
  /// The shelf needs it to put its arrows on the midline of the cover, where
  /// the card keeps no control of its own.
  static const double coverSize = 120;

  final RecommendedTrack track;
  final SourceLabel? source;
  final bool isFavorite;
  final bool selected;
  final bool playing;
  final bool waitsForDoubleClick;
  final Map<String, SourceLabel> sourceLabels;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToQueue;
  final VoidCallback onDismiss;
  final VoidCallback onDismissArtist;
  final VoidCallback onDetails;

  const RecommendationCard({
    super.key,
    required this.track,
    required this.source,
    required this.isFavorite,
    required this.selected,
    required this.playing,
    required this.waitsForDoubleClick,
    required this.sourceLabels,
    required this.onTap,
    required this.onDoubleTap,
    required this.onToggleFavorite,
    required this.onAddToQueue,
    required this.onDismiss,
    required this.onDismissArtist,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final song = track.song;
    final reason = discoveryReasonText(context, track.reason, sourceLabels);

    return SizedBox(
      width: 132,
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CompactTokens.radius12),
          side: BorderSide(
            color: selected
                ? accent.withValues(alpha: 0.45)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: TrackClickArea(
          onClick: onTap,
          onDoubleClick: onDoubleTap,
          waitsForDoubleClick: waitsForDoubleClick,
          hoverColor: accent.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(CompactTokens.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ArtworkThumb(
                      path: song.albumArtPath,
                      imageUrl: song.artworkUrl,
                      size: coverSize,
                      radius: CompactTokens.radius10,
                    ),
                    if (playing)
                      Positioned(
                        left: 2,
                        top: 2,
                        child: RoundCardControl(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              size: CompactTokens.icon16,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: RoundCardControl(
                        child: FavoriteButton(
                          isFavorite: isFavorite,
                          onPressed: onToggleFavorite,
                        ),
                      ),
                    ),
                    if (source != null)
                      Positioned(
                        left: 2,
                        bottom: 2,
                        child: SourceBadge(label: source!, dense: true),
                      ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: RecommendationCardMenu(
                        canDismiss: !isFavorite,
                        onSelected: _run,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CompactTokens.space6),
                Text(
                  song.title.isEmpty
                      ? context.loc.trackUnknownTitle
                      : song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? accent : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist.isEmpty
                      ? context.loc.playerUnknownArtist
                      : song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: CompactTokens.space4),
                TuneTooltip(
                  message: reason,
                  child: Row(
                    children: [
                      Icon(
                        recommendationReasonIcon(track.reason.kind),
                        size: CompactTokens.icon12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _run(RecommendationCardAction action) {
    switch (action) {
      case RecommendationCardAction.queue:
        onAddToQueue();
        break;
      case RecommendationCardAction.dismiss:
        onDismiss();
        break;
      case RecommendationCardAction.lessArtist:
        onDismissArtist();
        break;
      case RecommendationCardAction.details:
        onDetails();
        break;
    }
  }
}
