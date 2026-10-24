import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/features/library/presentation/library_row_actions.dart';
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
class LibraryTrackCard extends StatelessWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final bool isFavorite;
  final SourceLabel? source;
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

    return Material(
      color: selected ? accent.withValues(alpha: 0.06) : Colors.transparent,
      child: Stack(
        children: [
          // The mark of the track that plays sits on the edge of the row
          // instead of taking room, so the columns stay on one grid.
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: accent),
            ),
          TrackClickArea(
            onClick: onTap,
            onDoubleClick: onDoubleTap,
            waitsForDoubleClick: waitsForDoubleClick,
            hoverColor: accent.withValues(alpha: 0.04),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // The album is the first column to go, then the facts of
                  // the file. A narrow window keeps the artist and the time,
                  // because those are what tell two tracks apart.
                  final width = constraints.maxWidth;
                  final showArtist = width >= 480;
                  final showFacts = width >= 600;
                  final showAlbum = width >= 820;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CompactTokens.space8,
                      vertical: CompactTokens.libraryRowPadding,
                    ),
                    child: Row(
                      children: [
                        TrackPosition(
                          index: index,
                          selected: selected,
                          playing: playing,
                        ),
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
                            message: song.title.isEmpty
                                ? context.loc.trackUnknownTitle
                                : song.title,
                            child: Text(
                              song.title.isEmpty
                                  ? context.loc.trackUnknownTitle
                                  : song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        if (showArtist) ...[
                          const SizedBox(width: CompactTokens.space8),
                          Expanded(
                            flex: 2,
                            child: TuneTooltip(
                              message: song.artist.trim().isEmpty
                                  ? context.loc.playerUnknownArtist
                                  : song.artist,
                              child: Text(
                                song.artist.trim().isEmpty
                                    ? context.loc.playerUnknownArtist
                                    : song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (showAlbum) ...[
                          const SizedBox(width: CompactTokens.space8),
                          Expanded(
                            flex: 3,
                            child: TuneTooltip(
                              message: song.album.trim(),
                              child: Text(
                                song.album.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (showFacts) ...[
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
                            formatDuration(
                              Duration(milliseconds: song.durationInMillis),
                            ),
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
