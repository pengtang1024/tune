import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_album.dart';
import 'package:tune/features/library/domain/library_layout.dart';
import 'package:tune/features/library/presentation/library_row_metrics.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The library as the rows of the group list.
///
/// A table of tracks repeats the album name on every line; a group row says
/// it once — cover, name, whose it is, how much it holds — and a click opens
/// its tracks. A group that holds one track is that track: it is drawn as a
/// track row, in the same list and order, and a click plays it. The rows are
/// the list; there is no mode and no switch.
class LibraryGroupRows extends StatelessWidget {
  /// The rows to draw, in the order [libraryRowsOf] gave them.
  final List<LibraryListRow> rows;

  /// The noun the page's groups carry, from [libraryLayoutForKinds].
  ///
  /// It decides the unit of the count: songs, episodes or chapters. A page
  /// groups only while its scope names one kind, so one noun fits the list.
  final LibraryGroupingLabel groupingLabel;

  /// The widths of the columns of a track row, measured by the page.
  ///
  /// The page measures both lists with one ruler, so a single row and a row
  /// of the album view line up on the same columns.
  final LibraryRowMetrics metrics;

  /// Opens one group: its tracks replace the rows below.
  final ValueChanged<LibraryAlbum> onOpen;

  /// Draws one single row from the one track-row implementation of the page.
  final Widget Function(Song song, int index) buildTrackRow;

  /// What the whole list holds for a screen reader; a row says its own count.
  final int? totalTracks;

  /// The cover of a group row: bigger than a track row's on purpose, because
  /// the cover is what a reader recognises a group by while scanning.
  static const double _coverSize = CompactTokens.libraryGroupArtwork;

  /// The height of a group row: the cover and its two lines of text.
  static const double _rowHeight = CompactTokens.libraryGroupRowHeight;

  const LibraryGroupRows({
    super.key,
    required this.rows,
    required this.groupingLabel,
    required this.metrics,
    required this.onOpen,
    required this.buildTrackRow,
    this.totalTracks,
  });

  @override
  Widget build(BuildContext context) {
    final list = ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        0,
        CompactTokens.pageGutter,
        CompactTokens.space8,
      ),
      // Fixing the extent is only honest while every row is as tall as the
      // next: two lines of text take the same room as long as the text scale
      // is the default, and a track row takes the height the table measured.
      // A list that holds both heights must let every row measure itself.
      itemExtent: _itemExtent(context),
      // A row keeps no state.
      addAutomaticKeepAlives: false,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return switch (row) {
          LibraryAlbumRow(:final album) => _GroupRow(
            album: album,
            groupingLabel: groupingLabel,
            onOpen: () => onOpen(album),
          ),
          LibrarySingleRow(song: final song, index: final trackIndex) =>
            buildTrackRow(song, trackIndex),
        };
      },
    );

    final total = totalTracks;
    if (total == null) return list;
    return Semantics(
      container: true,
      label: context.loc.libraryTrackCount(total),
      child: list,
    );
  }

  /// The height every row of this list shares, or null while two kinds of
  /// row are in it.
  double? _itemExtent(BuildContext context) {
    var groups = false;
    var tracks = false;
    for (final row in rows) {
      if (row is LibraryAlbumRow) {
        groups = true;
      } else {
        tracks = true;
      }
    }
    if (groups && tracks) return null;
    if (tracks) return metrics.extent;
    return _isDefaultTextScale(context) ? _rowHeight : null;
  }

  static bool _isDefaultTextScale(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return (scaler.scale(1) - 1).abs() < 0.01;
  }
}

/// One row of the group list.
class _GroupRow extends StatelessWidget {
  final LibraryAlbum album;
  final LibraryGroupingLabel groupingLabel;
  final VoidCallback onOpen;

  const _GroupRow({
    required this.album,
    required this.groupingLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = album.name.isEmpty
        ? context.loc.libraryUnknownAlbum
        : album.name;
    final artist = album.hasMultipleArtists
        ? context.loc.libraryVariousArtists
        : album.artist.isEmpty
        ? context.loc.playerUnknownArtist
        : album.artist;
    // A single that names itself after its artist would print the same words
    // twice; the second line is dropped rather than repeated.
    final showArtist =
        artist.toLowerCase() != name.toLowerCase() || album.hasMultipleArtists;

    return TuneTooltip(
      message: name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('library-group-${album.key}'),
          onTap: onOpen,
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CompactTokens.space8,
              ),
              child: Row(
                children: [
                  ArtworkThumb(
                    path: album.coverPath,
                    imageUrl: album.coverUrl,
                    size: LibraryGroupRows._coverSize,
                    radius: CompactTokens.radius6,
                  ),
                  const SizedBox(width: CompactTokens.space12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (showArtist) ...[
                          const SizedBox(height: 2),
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: CompactTokens.space8),
                  Text(
                    _countOf(context, album, groupingLabel),
                    style: CompactTypography.mono(
                      theme.colorScheme.onSurfaceVariant,
                      size: CompactTypeScale.mark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// What the group holds, in the unit of the page's scope.
  static String _countOf(
    BuildContext context,
    LibraryAlbum album,
    LibraryGroupingLabel label,
  ) {
    return switch (label) {
      LibraryGroupingLabel.album => context.loc.libraryTrackCount(
        album.trackCount,
      ),
      LibraryGroupingLabel.show => context.loc.libraryEpisodeCount(
        album.trackCount,
      ),
      LibraryGroupingLabel.book => context.loc.libraryChapterCount(
        album.trackCount,
      ),
    };
  }
}
