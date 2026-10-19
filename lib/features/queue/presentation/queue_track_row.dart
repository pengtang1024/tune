import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/track_meta.dart';

/// A track of the play queue.
///
/// The row owns the presentation of a queue entry; the page only decides
/// what happens when it is played, moved or removed.
class QueueTrackRow extends StatelessWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final String? sourceName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const QueueTrackRow({
    super.key,
    required this.song,
    required this.index,
    required this.selected,
    required this.playing,
    this.sourceName,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Material(
      color: selected ? accent.withValues(alpha: 0.06) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: accent.withValues(alpha: 0.04),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 2,
                height: double.infinity,
                color: selected ? accent : Colors.transparent,
              ),
              const SizedBox(width: CompactTokens.space8),
              Expanded(
                child: TrackMeta(
                  song: song,
                  index: index,
                  sourceName: sourceName,
                  selected: selected,
                  playing: playing,
                  artworkSize: 32,
                ),
              ),
              const SizedBox(width: CompactTokens.space4),
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: CompactTokens.icon16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
              _RemoveButton(onPressed: onRemove),
              const SizedBox(width: CompactTokens.space4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action that takes the track out of the queue.
class _RemoveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RemoveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        tooltip: context.loc.remove,
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded, size: 14),
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
