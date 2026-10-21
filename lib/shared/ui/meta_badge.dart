import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
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

/// A chip that carries one fact and writes its words.
///
/// This is the one chip in the app that writes words: the details panel names
/// every fact of a track and gives its value, because that is the one place
/// where a reader comes to look a track up. Everywhere else a chip keeps the
/// words in the tooltip and shows the icon alone.
class MetaChip extends StatelessWidget {
  /// The icon that lets a reader recognise the fact at a glance.
  final IconData? icon;

  /// The name of the fact, such as the format of a track.
  final String? label;

  /// What the fact says, such as the name of the format.
  final String? value;

  /// The words the tooltip adds, for the reader who wants to know more.
  final String? tooltip;

  /// The colour of the chip, which tells the reader what kind of fact it is.
  final FactTone tone;

  const MetaChip({
    super.key,
    this.icon,
    this.label,
    this.value,
    this.tooltip,
    this.tone = FactTone.neutral,
  }) : assert(label != null || value != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = factToneColor(tone, theme.colorScheme);

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.space8,
        vertical: CompactTokens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CompactTokens.radius6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: CompactTokens.icon12, color: color),
            const SizedBox(width: CompactTokens.space4),
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
          if (label != null && value != null)
            const SizedBox(width: CompactTokens.space4),
          if (value != null)
            Text(
              value!,
              style: CompactTypography.mono(
                theme.colorScheme.onSurface,
                size: CompactTypeScale.mark,
                letterSpacing: 0.3,
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

/// A chip that carries a value too long for the line it stands in.
///
/// The icon says which value it is, the colour says that the value can be
/// taken away, and the value itself stands in the tooltip: a path and an
/// address are longer than a line, so they are not written out. The line
/// says what the thing is, and the chip hands the whole value over when the
/// pointer rests on it.
class CopyChip extends StatelessWidget {
  /// The value that the chip carries, and takes away with a click.
  final String address;

  /// The words that name the action, for the screen reader.
  ///
  /// The card of the tooltip says the value; the screen reader says what the
  /// chip does, because a value on its own does not say that it can be taken.
  final String hint;

  const CopyChip({super.key, required this.address, required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(CompactTokens.radius6);

    final mark = Container(
      width: CompactTokens.chipBox,
      height: CompactTokens.chipBox,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: radius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Icon(
        Icons.copy_rounded,
        size: CompactTokens.icon14,
        color: theme.colorScheme.primary,
      ),
    );

    return TuneTooltip(
      message: address,
      label: hint,
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: radius,
        child: mark,
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.trackDetailsCopied),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }
}
