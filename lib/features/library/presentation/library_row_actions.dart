import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/dense_icon_action.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/track_details_button.dart';

/// The actions at the end of a library row.
///
/// The three actions keep one size and one rhythm, so the columns of the
/// table end on the same edge whatever the width of the window is. They use
/// the dense primitive of a row and not the button of a page: the ink, the
/// focus and the keyboard stay, the page-sized box does not.
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
    // The row of actions keeps its rhythm without a spacer between the
    // buttons: the gap is part of the row, not an element of its own.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CompactTokens.space4,
      children: [
        TrackDetailsButton(
          song: song,
          source: source,
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          dense: true,
        ),
        FavoriteButton(
          isFavorite: isFavorite,
          onPressed: onToggleFavorite,
          dense: true,
        ),
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
    return DenseIconAction(
      icon: Icons.add_rounded,
      tooltip: context.loc.libraryAddToQueue,
      onPressed: onPressed,
    );
  }
}
