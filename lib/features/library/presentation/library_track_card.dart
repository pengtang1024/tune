import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/features/library/presentation/library_row_actions.dart';
import 'package:tune/features/library/presentation/library_row_metrics.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/track_click_area.dart';
import 'package:tune/shared/ui/track_fact_strip.dart';
import 'package:tune/shared/ui/track_position.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
import 'package:tune/shared/utils/duration_format.dart';

/// A track of the library table.
///
/// A library is read as a table: the title, the artist and the album sit in
/// columns of their own, so a reader can scan a hundred names without the
/// second line of every row pushing the next track out of the window. The
/// columns that do not fit the window drop out one by one: the album first,
/// then the facts, then the artist. The title always stays.
///
/// The row is a pure composition. The viewport hands it the columns and the
/// height it resolved once, the hint layer owns every card, and the dense
/// actions keep their ink without the box of a page button.
class LibraryTrackCard extends StatelessWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final bool isFavorite;
  final SourceLabel? source;

  /// What the viewport resolved for this row.
  ///
  /// The row does not measure itself: the list knows its width and its text
  /// scale, and every row reads the same answer.
  final LibraryRowMetrics metrics;

  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  /// Whether a click waits for a possible second click before it plays.
  ///
  /// A double click that only likes the track may not play it, so the
  /// click has to wait to see whether a second click follows.
  final bool waitsForDoubleClick;
  final VoidCallback onAddToQueue;
  final VoidCallback onToggleFavorite;

  const LibraryTrackCard({
    super.key,
    required this.song,
    required this.index,
    required this.selected,
    required this.playing,
    required this.isFavorite,
    this.source,
    required this.metrics,
    required this.onTap,
    required this.onDoubleTap,
    required this.waitsForDoubleClick,
    required this.onAddToQueue,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final unknownTitle = context.loc.trackUnknownTitle;
    final artist = song.artist.trim().isEmpty
        ? context.loc.playerUnknownArtist
        : song.artist;
    final album = song.album.trim();

    Widget row = TrackClickArea(
      onClick: onTap,
      onDoubleClick: onDoubleTap,
      waitsForDoubleClick: waitsForDoubleClick,
      hoverColor: accent.withValues(alpha: 0.04),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            // The mark of the track that plays sits on the edge instead of
            // taking room, so the columns stay on one grid. The edge is
            // always there and only changes colour: a row that gains the
            // mark must not change shape, or the second click of a double
            // click lands in a new click area and the track is played
            // instead of marked.
            left: BorderSide(
              width: 2,
              color: selected ? accent : Colors.transparent,
            ),
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CompactTokens.space8,
            vertical: CompactTokens.libraryRowPadding,
          ),
          child: Row(
            children: [
              TrackPosition(index: index, selected: selected, playing: playing),
              const SizedBox(width: CompactTokens.space8),
              ArtworkThumb(
                path: song.albumArtPath,
                imageUrl: song.artworkUrl,
                size: CompactTokens.libraryArtwork,
                radius: CompactTokens.radius6,
              ),
              const SizedBox(width: CompactTokens.space10),
              Expanded(
                flex: 5,
                child: TuneTooltip(
                  message: song.title.isEmpty ? unknownTitle : song.title,
                  child: Text(
                    song.title.isEmpty ? unknownTitle : song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
              ),
              if (metrics.showArtist) ...[
                const SizedBox(width: CompactTokens.space8),
                Expanded(
                  flex: 2,
                  child: TuneTooltip(
                    message: artist,
                    child: Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
              if (metrics.showAlbum) ...[
                const SizedBox(width: CompactTokens.space8),
                Expanded(
                  flex: 3,
                  child: TuneTooltip(
                    message: album,
                    child: Text(
                      album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
              if (metrics.showFacts) ...[
                const SizedBox(width: CompactTokens.space8),
                TrackFactStrip(song: song),
              ],
              if (source != null) ...[
                const SizedBox(width: CompactTokens.space8),
                SourceBadge(label: source!, dense: true),
              ],
              const SizedBox(width: CompactTokens.space8),
              if (!song.isLiveStream)
                Text(
                  formatDuration(Duration(milliseconds: song.durationInMillis)),
                  style: CompactTypography.mono(
                    theme.colorScheme.onSurfaceVariant,
                    size: CompactTypeScale.mark,
                  ),
                ),
              const SizedBox(width: CompactTokens.space4),
              LibraryRowActions(
                song: song,
                source: source,
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite,
                onAddToQueue: onAddToQueue,
              ),
            ],
          ),
        ),
      ),
    );

    return Material(
      color: selected ? accent.withValues(alpha: 0.06) : Colors.transparent,
      child: row,
    );
  }
}
