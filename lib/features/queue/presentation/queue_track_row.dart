import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/dense_icon_action.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/track_click_area.dart';
import 'package:tune/shared/ui/track_meta.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// A track of the play queue.
///
/// The row owns the presentation of a queue entry; the page only decides
/// what happens when it is played, moved or removed.
class QueueTrackRow extends StatelessWidget {
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
  final VoidCallback onRemove;
  final VoidCallback onToggleFavorite;

  /// Whether the row sits in a panel rather than a full page.
  ///
  /// The panel row keeps the title on one line and the artist, the source and
  /// the duration on the next, so the panel stays readable without the fact
  /// strip and the details action of a page row.
  final bool dense;

  const QueueTrackRow({
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
    required this.onRemove,
    required this.onToggleFavorite,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Material(
      color: selected ? accent.withValues(alpha: 0.06) : Colors.transparent,
      child: TrackClickArea(
        onClick: onTap,
        onDoubleClick: onDoubleTap,
        waitsForDoubleClick: waitsForDoubleClick,
        hoverColor: accent.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Stack(
            children: [
              // The mark of the track that plays sits on the edge of the row
              // instead of taking room, so the columns of the queue line up
              // with the columns of the library.
              if (selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: accent),
                ),
              Padding(
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
                        isFavorite: isFavorite,
                        onToggleFavorite: onToggleFavorite,
                        dense: dense,
                      ),
                    ),
                    const SizedBox(width: CompactTokens.space4),
                    FavoriteButton(
                      isFavorite: isFavorite,
                      onPressed: onToggleFavorite,
                    ),
                    const SizedBox(width: CompactTokens.space4),
                    _DragHandle(index: index),
                    _RemoveButton(onPressed: onRemove),
                    const SizedBox(width: CompactTokens.space4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The handle that starts a reorder, with a hint and a hover state.
class _DragHandle extends StatefulWidget {
  final int index;

  const _DragHandle({required this.index});

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: context.loc.queueReorderTooltip,
      child: ReorderableDragStartListener(
        index: widget.index,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: CompactTokens.fastMotion,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hovered
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(CompactTokens.radius6),
            ),
            child: Icon(
              Icons.drag_indicator_rounded,
              size: CompactTokens.icon16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
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
    return DenseIconAction(
      icon: Icons.remove_rounded,
      tooltip: context.loc.remove,
      onPressed: onPressed,
      size: 28,
      iconSize: CompactTokens.icon14,
    );
  }
}
