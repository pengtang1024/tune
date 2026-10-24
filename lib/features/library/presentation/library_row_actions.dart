import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/track_details_button.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The actions at the end of a library row.
///
/// The three actions keep one size and one rhythm, so the columns of the
/// table end on the same edge whatever the width of the window is.
class LibraryRowActions extends StatelessWidget {
  final Song song;
  final SourceLabel? source;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback onAddToQueue;

  const LibraryRowActions({
    super.key,
    required this.song,
    this.source,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TrackDetailsButton(
          song: song,
          source: source,
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          dense: true,
        ),
        const SizedBox(width: CompactTokens.space4),
        FavoriteButton(
          isFavorite: isFavorite,
          onPressed: onToggleFavorite,
          dense: true,
        ),
        const SizedBox(width: CompactTokens.space4),
        _AddToQueueButton(onPressed: onAddToQueue),
      ],
    );
  }
}

/// Action that appends the track to the play queue.
class _AddToQueueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddToQueueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: context.loc.libraryAddToQueue,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: CompactTokens.icon16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: CompactTokens.libraryRowAction,
          height: CompactTokens.libraryRowAction,
        ),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
