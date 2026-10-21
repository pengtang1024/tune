import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/utils/text_width.dart';

/// The track the panel of its details belongs to.
class TrackDetailHeader extends StatelessWidget {
  final Song song;

  /// Whether the track is one of the favorites.
  final bool isFavorite;

  /// What the click on the heart does.
  ///
  /// The panel is a shared piece of the interface and knows nothing about the
  /// favorites, so the caller says whether the track can be marked here. The
  /// heart only shows when there is something to mark.
  final VoidCallback? onToggleFavorite;

  const TrackDetailHeader({
    super.key,
    required this.song,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArtworkThumb(
          path: song.albumArtPath,
          imageUrl: song.artworkUrl,
          size: CompactTokens.artworkHero,
          radius: 12,
        ),
        const SizedBox(width: CompactTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.title.isEmpty ? context.loc.trackUnknownTitle : song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CompactTypography.asDisplay(
                  theme.textTheme.titleMedium,
                  size: CompactTypeScale.displaySmall,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: CompactTokens.space4),
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
            ],
          ),
        ),
        const SizedBox(width: CompactTokens.space8),
        if (onToggleFavorite case final action?)
          FavoriteButton(isFavorite: isFavorite, onPressed: action),
      ],
    );
  }
}

/// The width the head of the panel of a track wants.
///
/// The head is as wide as the name of the track or the name of the one who
/// made it, up to a limit: the panel is as wide as the table of the facts,
/// and a very long name must not widen the whole panel for the sake of one
/// line.
double trackDetailHeaderWidth(
  BuildContext context,
  String title,
  String artist, {
  required bool hasHeart,
}) {
  final theme = Theme.of(context);
  final titleWidth = measureTextWidth(
    context,
    title,
    CompactTypography.asDisplay(
      theme.textTheme.titleMedium,
      size: CompactTypeScale.displaySmall,
      height: 1.15,
    ),
  );
  final artistWidth = measureTextWidth(
    context,
    artist,
    theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
  final words = math.max(
    math.min(titleWidth, CompactTokens.detailPanelTitleWidth),
    math.min(artistWidth, CompactTokens.detailPanelTitleWidth),
  );

  return CompactTokens.artworkHero +
      CompactTokens.space12 +
      words +
      (hasHeart ? CompactTokens.space8 + CompactTokens.controlTiny : 0);
}
