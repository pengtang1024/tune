import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/presentation/library_row_metrics.dart';
import 'package:tune/features/library/presentation/library_row_tail.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/track_click_area.dart';
import 'package:tune/shared/ui/track_position.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
import 'package:tune/shared/utils/date_format.dart';

/// A track of the library table.
///
/// The title, artist, album, added date and the 102px tail sit on the grid
/// [LibraryRowMetrics] resolved once. The row is a pure composition; only
/// the hover that brings the two extra actions out lives here.
class LibraryTrackCard extends StatefulWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final bool isFavorite;

  /// Whether the last playback of the track failed.
  final bool unavailable;
  final SourceLabel? source;

  /// What the viewport resolved for this row.
  final LibraryRowMetrics metrics;

  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  /// Whether a click waits for a possible second click before it plays.
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
    this.unavailable = false,
    this.source,
    required this.metrics,
    required this.onTap,
    required this.onDoubleTap,
    required this.waitsForDoubleClick,
    required this.onAddToQueue,
    required this.onToggleFavorite,
  });

  @override
  State<LibraryTrackCard> createState() => _LibraryTrackCardState();
}

class _LibraryTrackCardState extends State<LibraryTrackCard> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final metrics = widget.metrics;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final unknownTitle = context.loc.trackUnknownTitle;
    final artist = song.artist.trim().isEmpty
        ? context.loc.playerUnknownArtist
        : song.artist;
    final album = song.album.trim();

    Widget row = TrackClickArea(
      onClick: widget.onTap,
      onDoubleClick: widget.onDoubleTap,
      waitsForDoubleClick: widget.waitsForDoubleClick,
      hoverColor: accent.withValues(alpha: 0.04),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 2,
              color: widget.selected ? accent : Colors.transparent,
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
              TrackPosition(
                index: widget.index,
                selected: widget.selected,
                playing: widget.playing,
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
                child: Row(
                  children: [
                    Flexible(
                      child: TuneTooltip(
                        message: song.title.isEmpty ? unknownTitle : song.title,
                        child: Text(
                          song.title.isEmpty ? unknownTitle : song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: widget.selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: widget.selected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                    ),
                    if (widget.unavailable) ...[
                      const SizedBox(width: CompactTokens.space4),
                      TuneTooltip(
                        message: context.loc.songMayBeUnavailable,
                        child: Icon(
                          Icons.link_off_rounded,
                          size: CompactTokens.icon14,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (metrics.showArtist) ...[
                const SizedBox(width: CompactTokens.space8),
                Expanded(
                  flex: 3,
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
              if (metrics.showAdded)
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatAddedAt(song.dateAdded),
                      style: CompactTypography.mono(
                        theme.colorScheme.onSurfaceVariant,
                        size: CompactTypeScale.mark,
                      ),
                    ),
                  ),
                ),
              LibraryRowTail(
                song: song,
                source: widget.source,
                isFavorite: widget.isFavorite,
                hovering: _hovering,
                onToggleFavorite: widget.onToggleFavorite,
                onAddToQueue: widget.onAddToQueue,
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: widget.selected
            ? accent.withValues(alpha: 0.06)
            : Colors.transparent,
        child: row,
      ),
    );
  }
}
