import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/dense_icon_action.dart';
import 'package:tune/shared/ui/track_detail_sheet.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The action that opens everything that is known about a track.
class TrackDetailsButton extends StatelessWidget {
  final Song song;
  final SourceLabel? source;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  /// Whether the button sits in a compact row.
  ///
  /// The library table is shorter than a full page row, so its action is
  /// one step smaller and still keeps the same icon and tooltip.
  final bool dense;

  const TrackDetailsButton({
    super.key,
    required this.song,
    this.source,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = context.loc.trackDetailsTooltip;
    void openDetails() => showTrackDetailSheet(
      context,
      song,
      source: source,
      isFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
    );

    if (dense) {
      return DenseIconAction(
        icon: Icons.info_outline_rounded,
        tooltip: message,
        onPressed: openDetails,
      );
    }

    final size = CompactTokens.controlTiny;

    return TuneTooltip(
      message: message,
      child: IconButton(
        onPressed: openDetails,
        icon: const Icon(
          Icons.info_outline_rounded,
          size: CompactTokens.icon16,
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: size, height: size),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
