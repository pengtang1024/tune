import 'package:flutter/material.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/shared/ui/meta_chip.dart';
import 'package:tune/shared/ui/source_mark.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The mark of the source a track came from.
///
/// The mark is an icon, not a name, so a row of tracks keeps the same shape
/// no matter how long the name of the source is: the brand of a source and
/// the name it has in the language of the reader would make the row grow and
/// shrink with every source.
///
/// The colour says what kind of source it is, the icon says which one it is.
///
/// The mouse names the source — the brand and what the source is called in
/// the language of the reader — and the details panel writes it down.
class SourceBadge extends StatelessWidget {
  final SourceLabel label;
  final bool dense;
  final VoidCallback? onTap;

  const SourceBadge({
    super.key,
    required this.label,
    this.dense = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = factToneColor(sourceToneOf(label.kind), theme.colorScheme);
    final radius = dense ? 5.0 : 6.0;

    final mark = Container(
      width: dense ? 18 : 22,
      height: dense ? 18 : 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Icon(
        sourceIconOf(label.type, label.kind),
        size: dense ? 11 : 13,
        color: color,
      ),
    );

    final badge = onTap == null
        ? mark
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: mark,
          );

    return TuneTooltip(message: _message, child: badge);
  }

  /// The full name of the source: the brand and what it is called here.
  String get _message {
    if (label.localizedName.isEmpty) return label.name;
    return '${label.name} · ${label.localizedName}';
  }
}
