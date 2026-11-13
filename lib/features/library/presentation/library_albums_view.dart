import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/album_summary.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/features/library/presentation/library_filter_labels.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/track_fact.dart';
import 'package:tune/shared/ui/translated_text.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The albums of the library as a grid of covers, in three sections.
///
/// The grid is the browsing side of the library: a reader who does not know
/// the name of a track can recognise the cover, and one card stands for a
/// whole album instead of one row of its tracks. Songs, shows and books are
/// kept apart because a show is counted in episodes and a book in chapters;
/// the section headers appear only while at least two of them hold anything.
/// A station is not an album, so radio never reaches the wall.
class LibraryAlbumsView extends StatelessWidget {
  final List<AlbumSummary> albums;

  /// Keeps the place of the grid while an album is open.
  final ScrollController? controller;

  /// The album that holds the track that plays right now, if any.
  final String? currentAlbumKey;

  /// Opens the album and shows its tracks.
  final ValueChanged<AlbumSummary> onOpen;

  /// Plays the whole album without opening it.
  final ValueChanged<AlbumSummary> onPlay;

  /// Whether an album name may carry a translation and its original.
  ///
  /// The grid has a fixed caption, so the room for the second line is
  /// reserved by the grid and not by each card.
  final bool bilingual;

  /// The longest side of a cover.
  ///
  /// The grid packs the covers as tightly as the window allows; a cover is
  /// still big enough to recognise, and the album name under it does the
  /// rest. The limit is what keeps a small window at four or five columns
  /// instead of one card per screen.
  static const double _maxCover = 128;

  /// The room under a cover for the name, the artist and the count.
  static const double _captionHeight = 60;
  static const double _captionHeightBilingual = 76;

  const LibraryAlbumsView({
    super.key,
    required this.albums,
    required this.onOpen,
    required this.onPlay,
    this.currentAlbumKey,
    this.controller,
    this.bilingual = false,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = CompactTokens.space12;
    const gutter = CompactTokens.pageGutter;
    final sections = [
      for (final kind in const [
        ContentKind.music,
        ContentKind.podcast,
        ContentKind.audiobook,
      ])
        (
          kind: kind,
          albums: albums
              .where((album) => album.kind == kind)
              .toList(growable: false),
        ),
    ].where((section) => section.albums.isNotEmpty).toList(growable: false);
    // One section needs no name: the wall already says what the library holds.
    final showHeaders = sections.length >= 2;

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
            (bilingual ? _captionHeightBilingual : _captionHeight) *
            MediaQuery.textScalerOf(context).scale(1);

        return CustomScrollView(
          controller: controller,
          slivers: [
            for (var index = 0; index < sections.length; index++) ...[
              if (showHeaders)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      index == 0 ? 0 : CompactTokens.space12,
                      gutter,
                      CompactTokens.space8,
                    ),
                    child: Text(
                      '${filterKindLabel(context, sections[index].kind)} · '
                      '${sections[index].albums.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: gutter),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: cell + caption,
                  ),
                  itemCount: sections[index].albums.length,
                  itemBuilder: (context, itemIndex) {
                    final album = sections[index].albums[itemIndex];
                    return _AlbumCard(
                      album: album,
                      coverSize: cell,
                      current: album.key == currentAlbumKey,
                      onOpen: () => onOpen(album),
                      onPlay: () => onPlay(album),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: CompactTokens.space8)),
          ],
        );
      },
    );
  }
}

class _AlbumCard extends StatefulWidget {
  final AlbumSummary album;
  final double coverSize;
  final bool current;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  const _AlbumCard({
    required this.album,
    required this.coverSize,
    required this.current,
    required this.onOpen,
    required this.onPlay,
  });

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _hovered = false;

  /// Whether the card, or the play button on it, holds the keyboard focus.
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final album = widget.album;
    final name = album.name.isEmpty
        ? context.loc.libraryUnknownAlbum
        : album.name;
    final artist = album.artist.isEmpty
        ? context.loc.playerUnknownArtist
        : album.artist;

    return Focus(
      // The card is not a stop of its own: the ink below is the stop. The
      // node hears the ink and the play button on the cover, so the keyboard
      // reaches the same actions as the pointer.
      canRequestFocus: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpen,
          onHover: (hovered) => setState(() => _hovered = hovered),
          borderRadius: CompactTokens.borderRadius8,
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        CompactTokens.radius8 + 2,
                      ),
                      border: widget.current
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: ArtworkThumb(
                      path: album.coverPath,
                      imageUrl: album.coverUrl,
                      size: widget.coverSize,
                      radius: CompactTokens.radius8,
                    ),
                  ),
                  if (widget.current)
                    Positioned(
                      left: CompactTokens.space6,
                      bottom: CompactTokens.space6,
                      child: _NowPlayingMark(),
                    ),
                  if (_focused || _hovered)
                    Positioned(
                      right: CompactTokens.space6,
                      bottom: CompactTokens.space6,
                      child: _PlayButton(onPressed: widget.onPlay),
                    ),
                ],
              ),
              const SizedBox(height: CompactTokens.space6),
              Row(
                children: [
                  Flexible(
                    child: TranslatedText(
                      text: name,
                      maxLines: 1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: widget.current
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: widget.current
                            ? theme.colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                  if (album.kind.isSpokenWord) ...[
                    const SizedBox(width: CompactTokens.space4),
                    MetaBadge(
                      icon: Icons.record_voice_over_rounded,
                      tooltip: filterKindLabel(context, album.kind),
                      tone: FactTone.secondary,
                      size: 12,
                    ),
                  ],
                ],
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
                switch (album.kind) {
                  ContentKind.podcast => context.loc.libraryEpisodeCount(
                    album.trackCount,
                  ),
                  ContentKind.audiobook => context.loc.libraryChapterCount(
                    album.trackCount,
                  ),
                  _ => context.loc.libraryTrackCount(album.trackCount),
                },
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The mark of the album that holds the track that plays.
class _NowPlayingMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(CompactTokens.radius6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Icon(
        Icons.equalizer_rounded,
        size: CompactTokens.icon14,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// The action that plays the album from the cover.
class _PlayButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: context.loc.searchPlayAll,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded, size: CompactTokens.icon18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
