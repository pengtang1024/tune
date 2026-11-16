import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/features/library/presentation/library_wall_columns.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/domain/library_collection.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The collections of the library, one card per instance.
///
/// A collection is opened rather than filtered: the card leads to the items
/// the collection holds, and an item leads to its tracks. Browsing an archive
/// that way keeps a shelf of short uploads from standing in the same list as
/// the songs a reader owns, which is what the flat table cannot express.
class LibraryCollectionsView extends StatelessWidget {
  final List<LibraryCollection> collections;
  final ScrollController? controller;
  final ValueChanged<LibraryCollection> onOpen;
  final ValueChanged<LibraryCollection>? onClear;

  const LibraryCollectionsView({
    super.key,
    required this.collections,
    required this.onOpen,
    this.onClear,
    this.controller,
  });

  /// The widest a cover grows before the grid asks for another column.
  static const double _maxCover = 168;

  static const double _captionHeight = 46;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) {
      return _EmptyCollections();
    }

    const spacing = CompactTokens.space12;
    const gutter = CompactTokens.pageGutter;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 列数由 libraryWallColumns 一处决定（窄页固定三列）。
        final columns = libraryWallColumns(
          constraints.maxWidth,
          maxCover: _maxCover,
        );
        final cell = wallCellWidth(constraints.maxWidth, columns);
        final caption =
            _captionHeight * MediaQuery.textScalerOf(context).scale(1);

        return GridView.builder(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            gutter,
            0,
            gutter,
            CompactTokens.space16,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cell + caption,
          ),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return _CollectionCard(
              collection: collection,
              coverSize: cell,
              onOpen: () => onOpen(collection),
              onClear: onClear == null ? null : () => onClear!(collection),
            );
          },
        );
      },
    );
  }
}

class _CollectionCard extends StatefulWidget {
  final LibraryCollection collection;
  final double coverSize;
  final VoidCallback onOpen;
  final VoidCallback? onClear;

  const _CollectionCard({
    required this.collection,
    required this.coverSize,
    required this.onOpen,
    this.onClear,
  });

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collection = widget.collection;
    final loc = context.loc;

    return Material(
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
                ArtworkThumb(
                  path: collection.artPath,
                  imageUrl: collection.artUrl,
                  size: widget.coverSize,
                  radius: CompactTokens.radius8,
                ),
                // The count sits on the cover because it is what tells two
                // collections apart at a glance: one holds ten songs, one
                // holds a thousand.
                Positioned(
                  right: CompactTokens.space6,
                  bottom: CompactTokens.space6,
                  child: _Tally(
                    text: loc.libraryTrackCount(collection.trackCount),
                  ),
                ),
                if (_hovered)
                  Positioned(
                    left: CompactTokens.space6,
                    bottom: CompactTokens.space6,
                    child: _OpenMark(tooltip: loc.libraryOpenCollection),
                  ),
                if (_hovered && widget.onClear != null)
                  Positioned(
                    right: CompactTokens.space6,
                    top: CompactTokens.space6,
                    child: _ClearMark(
                      tooltip: loc.sourcesClearSongs,
                      onPressed: widget.onClear!,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: CompactTokens.space6),
            Text(
              collection.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              loc.libraryCollectionItems(
                collection.itemCount,
                collection.trackCount,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

/// The count on a cover: dark pill, small numbers, never the loudest thing.
class _Tally extends StatelessWidget {
  final String text;

  const _Tally({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.scrim.withValues(alpha: 0.62),
        borderRadius: CompactTokens.borderRadius6,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CompactTokens.space6,
          vertical: 1,
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onInverseSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OpenMark extends StatelessWidget {
  final String tooltip;

  const _OpenMark({required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TuneTooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.scrim.withValues(alpha: 0.62),
          borderRadius: CompactTokens.borderRadius6,
        ),
        child: Padding(
          padding: const EdgeInsets.all(CompactTokens.space4),
          child: Icon(
            Icons.folder_open_rounded,
            size: CompactTokens.icon14,
            color: theme.colorScheme.onInverseSurface,
          ),
        ),
      ),
    );
  }
}

/// The pruning mark: a collection that brought in rows a reader does not
/// want is emptied from here, one shelf at a time.
class _ClearMark extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;

  const _ClearMark({required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TuneTooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.scrim.withValues(alpha: 0.62),
        borderRadius: CompactTokens.borderRadius6,
        child: InkWell(
          onTap: onPressed,
          borderRadius: CompactTokens.borderRadius6,
          child: Padding(
            padding: const EdgeInsets.all(CompactTokens.space4),
            child: Icon(
              Icons.clear_all_rounded,
              size: CompactTokens.icon14,
              color: theme.colorScheme.onInverseSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCollections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CompactTokens.pageGutter),
        child: Text(
          context.loc.libraryNoMatchSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
