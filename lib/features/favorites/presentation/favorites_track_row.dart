import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/track_click_area.dart';
import 'package:tune/shared/ui/track_meta.dart';

/// A track the user marked with a heart.
///
/// The row reads the track the way every other list of the app reads it, so
/// a favorite looks the same here as it does in the library.
class FavoritesTrackRow extends StatelessWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final SourceLabel? source;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  /// Whether a click waits for a possible second click before it plays.
  ///
  /// A double click that only likes the track may not play it, so the
  /// click has to wait to see whether a second click follows.
  final bool waitsForDoubleClick;
  final VoidCallback onToggleFavorite;

  const FavoritesTrackRow({
    super.key,
    required this.song,
    required this.index,
    required this.selected,
    required this.playing,
    this.source,
    required this.onTap,
    required this.onDoubleTap,
    required this.waitsForDoubleClick,
    required this.onToggleFavorite,
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
                FavoriteButton(isFavorite: true, onPressed: onToggleFavorite),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
