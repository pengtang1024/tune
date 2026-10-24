import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/domain/library_album.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';

/// The albums of the library as a grid of covers.
///
/// The grid is the browsing side of the library: a reader who does not know
/// the name of a track can recognise the cover, and one card stands for a
/// whole album instead of one row of its tracks. The songs view stays one
/// click away for the reader who does know the name.
class LibraryAlbumsView extends StatelessWidget {
  final List<LibraryAlbum> albums;
  final ValueChanged<LibraryAlbum> onOpen;

  /// The longest side of a cover.
  ///
  /// The grid packs the covers as tightly as the window allows; a cover is
  /// still big enough to recognise, and the album name under it does the
  /// rest. The limit is what keeps a small window at four or five columns
  /// instead of one card per screen.
  static const double _maxCover = 128;

  /// The room under a cover for the name, the artist and the count.
  static const double _captionHeight = 60;

  const LibraryAlbumsView({
    super.key,
    required this.albums,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = CompactTokens.space12;
    const gutter = CompactTokens.pageGutter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - gutter * 2;
        final columns = ((width + spacing) / (_maxCover + spacing))
            .ceil()
            .clamp(2, 10);
        final cell = (width - spacing * (columns - 1)) / columns;
        // The caption grows with the text of the desktop, like every other
        // box that holds words; the cover keeps the size the grid gave it.
        final caption =
            _captionHeight * MediaQuery.textScalerOf(context).scale(1);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            gutter,
            0,
            gutter,
            CompactTokens.space8,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cell + caption,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return _AlbumCard(
              album: album,
              coverSize: cell,
              onTap: () => onOpen(album),
            );
          },
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final LibraryAlbum album;
  final double coverSize;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.coverSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = album.name.isEmpty
        ? context.loc.libraryUnknownAlbum
        : album.name;
    final artist = album.isUnknown && album.hasMultipleArtists
        ? context.loc.libraryVariousArtists
        : (album.artist.isEmpty
              ? context.loc.playerUnknownArtist
              : album.artist);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CompactTokens.borderRadius8,
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkThumb(
              path: album.coverPath,
              imageUrl: album.coverUrl,
              size: coverSize,
              radius: CompactTokens.radius8,
            ),
            const SizedBox(height: CompactTokens.space6),
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
            const SizedBox(height: 2),
            Text(
              context.loc.libraryTrackCount(album.trackCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
