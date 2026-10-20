import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/track_meta.dart';

/// A track of the library list.
///
/// The card owns the whole presentation of a library row; the page only
/// decides what happens when it is tapped or when a track is queued.
class LibraryTrackCard extends StatelessWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final SourceLabel? source;
  final VoidCallback onTap;
  final VoidCallback onAddToQueue;

  const LibraryTrackCard({
    super.key,
    required this.song,
    required this.index,
    required this.selected,
    required this.playing,
    this.source,
    required this.onTap,
    required this.onAddToQueue,
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
        child: InkWell(
          onTap: onTap,
          hoverColor: accent.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CompactTokens.space8,
              vertical: CompactTokens.space8,
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

    return IconButton(
      tooltip: context.loc.libraryAddToQueue,
      onPressed: onPressed,
      icon: const Icon(Icons.playlist_add_rounded, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
