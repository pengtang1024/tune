import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/shared/ui/track_fact.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The colour a tone paints its fact with.
Color factToneColor(FactTone tone, ColorScheme colors) {
  return switch (tone) {
    FactTone.neutral => colors.onSurfaceVariant,
    FactTone.primary => colors.primary,
    FactTone.secondary => colors.secondary,
    FactTone.tertiary => colors.tertiary,
    FactTone.error => colors.error,
  };
}

/// A chip that carries one fact.
///
/// The chip shows an icon and the words of the fact. A place that reads a
/// track on purpose names the fact and gives its value; a place that only
/// hints at a fact shows the value alone and keeps the name for the tooltip.
class MetaChip extends StatelessWidget {
  final IconData? icon;

  /// The name of the fact, such as the format of a track.
  final String? label;

  /// What the fact says, such as the name of the format.
  final String? value;

  final String? tooltip;
  final FactTone tone;
  final bool dense;

  const MetaChip({
    super.key,
    this.icon,
    this.label,
    this.value,
    this.tooltip,
    this.tone = FactTone.neutral,
    this.dense = false,
  }) : assert(label != null || value != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = factToneColor(tone, theme.colorScheme);

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5 : 7,
        vertical: dense ? 1.5 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(dense ? 4 : 6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 9 : 11, color: color),
            SizedBox(width: dense ? 3 : 4),
          ],
          if (label != null)
            Text(
              label!,
              style: CompactTypography.mono(
                color,
                size: CompactTypeScale.mark,
                weight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          if (label != null && value != null) const SizedBox(width: 4),
          if (value != null)
            // The value is the part that can run long (the name of a source, a
            // genre list), so it is the part that gives up its room when the
            // chip does not fit. The name of the fact stays whole.
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CompactTypography.mono(
                  theme.colorScheme.onSurface,
                  size: CompactTypeScale.mark,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );

    final message = tooltip;
    if (message == null) return chip;
    return TuneTooltip(message: message, child: chip);
  }
}

/// An icon that stands for one fact.
///
/// The icon keeps its place in a row, the tooltip says what it means.
class MetaBadge extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final FactTone tone;
  final double size;
  final VoidCallback? onTap;

  const MetaBadge({
    super.key,
    required this.icon,
    required this.tooltip,
    this.tone = FactTone.neutral,
    this.size = 13,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = factToneColor(tone, Theme.of(context).colorScheme);
    final mark = Icon(icon, size: size, color: color);
    return TuneTooltip(
      message: tooltip,
      child: onTap == null
          ? mark
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: mark,
            ),
    );
  }
}
