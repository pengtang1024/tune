import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/track_click_area.dart';
import 'package:tune/shared/ui/track_meta.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// A track of the library list.
///
/// The card owns the whole presentation of a library row; the page only
/// decides what happens when it is tapped or when a track is queued.
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

    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space8),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CompactTokens.radius12),
          side: BorderSide(
            color: selected
                ? accent.withValues(alpha: 0.45)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: TrackClickArea(
          onClick: onTap,
          onDoubleClick: onDoubleTap,
          waitsForDoubleClick: waitsForDoubleClick,
          hoverColor: accent.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CompactTokens.space8,
              vertical: CompactTokens.listRowPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TrackMeta(
                    song: song,
                    index: index,
                    source: source,
                    selected: selected,
                    playing: playing,
                  ),
                ),
                const SizedBox(width: CompactTokens.space4),
                FavoriteButton(
                  isFavorite: isFavorite,
                  onPressed: onToggleFavorite,
                ),
                const SizedBox(width: CompactTokens.space4),
                _AddToQueueButton(onPressed: onAddToQueue),
              ],
            ),
          ),
        ),
      ),
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
        icon: const Icon(
          Icons.playlist_add_rounded,
          size: CompactTokens.icon18,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
