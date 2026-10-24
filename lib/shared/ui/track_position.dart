import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';

/// Position of a track in its list.
///
/// The current track replaces its number with the playback indicator so the
/// list always shows where the music is. The column is shared by the lists
/// of the shell, so a track keeps the same place in the library, the queue
/// and the favorites.
class TrackPosition extends StatelessWidget {
  final int index;
  final bool selected;
  final bool playing;

  /// The room the number or the indicator may take.
  final double width;

  const TrackPosition({
    super.key,
    required this.index,
    required this.selected,
    required this.playing,
    this.width = CompactTokens.positionColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Center(
        child: selected
            ? Icon(
                playing ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                size: CompactTokens.icon16,
                color: theme.colorScheme.primary,
              )
            : Text(
                '${index + 1}',
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant,
                  size: CompactTypeScale.mark,
                ),
              ),
      ),
    );
  }
}
