import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/dense_icon_action.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/track_details_button.dart';
import 'package:tune/shared/utils/duration_format.dart';

/// The 102px tail of a library row.
///
/// At rest it shows the source, the duration and the heart. Under the
/// pointer the facts step aside for the two actions of the row — details
/// and queue — while the heart stays pinned at the same right edge. Nothing
/// changes width, so the columns never jump.
class LibraryRowTail extends StatelessWidget {
  static const double width = 102;

  final Song song;
  final SourceLabel? source;
  final bool isFavorite;
  final bool hovering;
  final VoidCallback? onToggleFavorite;
  final VoidCallback onAddToQueue;

  const LibraryRowTail({
    super.key,
    required this.song,
    this.source,
    required this.isFavorite,
    required this.hovering,
    required this.onToggleFavorite,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
          children: [
            if (hovering) ...[
              TrackDetailsButton(
                song: song,
                source: source,
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite,
                dense: true,
              ),
              DenseIconAction(
                icon: Icons.add_rounded,
                tooltip: context.loc.libraryAddToQueue,
                onPressed: onAddToQueue,
              ),
            ] else ...[
              if (source != null) ...[
                SourceBadge(label: source!, dense: true),
                const SizedBox(width: CompactTokens.space4),
              ],
              if (!song.isLiveStream)
                Text(
                  formatDuration(
                    Duration(milliseconds: song.durationInMillis),
                  ),
                  style: CompactTypography.mono(
                    theme.colorScheme.onSurfaceVariant,
                    size: CompactTypeScale.mark,
                  ),
                ),
            ],
            const SizedBox(width: CompactTokens.space4),
              FavoriteButton(
                isFavorite: isFavorite,
                onPressed: onToggleFavorite,
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
