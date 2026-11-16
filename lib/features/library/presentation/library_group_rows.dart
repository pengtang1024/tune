import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/domain/library_album.dart';
import 'package:tune/features/library/domain/library_layout.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The library as rows of groups: one album, show or book per row.
///
/// A table of tracks repeats the album name on every line; a group row says
/// it once — cover, name, whose it is, how much it holds — and a click opens
/// its tracks. The rows are the list; there is no mode and no switch.
class LibraryGroupRows extends StatelessWidget {
  /// The groups to draw, in the order the library gave them.
  final List<LibraryAlbum> albums;

  /// The noun the page's groups carry, from [libraryLayoutForKinds].
  ///
  /// It decides the unit of the count: songs, episodes or chapters. A page
  /// groups only while its scope names one kind, so one noun fits the list.
  final LibraryGroupingLabel groupingLabel;

  /// Opens one group: its tracks replace the rows below.
  final ValueChanged<LibraryAlbum> onOpen;

  /// What the whole list holds for a screen reader; a row says its own count.
  final int? totalTracks;

  /// The cover of a group row: bigger than a track row's on purpose, because
  /// the cover is what a reader recognises a group by while scanning.
  static const double _coverSize = CompactTokens.libraryGroupArtwork;

  /// The height of a group row: the cover and its two lines of text.
  static const double _rowHeight = CompactTokens.libraryGroupRowHeight;

  const LibraryGroupRows({
    super.key,
    required this.albums,
    required this.groupingLabel,
    required this.onOpen,
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
      // Two lines of text always take the same room, so the list can fix its
      // extent; a larger text scale has to grow the row, so it steps aside.
      itemExtent: _isDefaultTextScale(context) ? _rowHeight : null,
      // A row keeps no state.
      addAutomaticKeepAlives: false,
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return _GroupRow(
          album: album,
          groupingLabel: groupingLabel,
          onOpen: () => onOpen(album),
        );
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
