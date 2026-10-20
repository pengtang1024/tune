import 'package:flutter/material.dart';
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
