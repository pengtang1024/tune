import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
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
/// The chip is the mark of the fact: the icon says which fact it is and the
/// colour says which class it belongs to. The words of the fact wait in the
/// tooltip, the way they wait in every other chip of the app — a chip that
/// writes its words grows with them, and a panel full of facts would turn
/// into a table of words.
///
/// A fact that has a main and a second half is the one exception: the chip
/// shows the main next to the icon, because the main is the name of the
/// thing itself. The second half waits in the tooltip.
class MetaChip extends StatelessWidget {
  /// The icon that lets a reader recognise the fact at a glance.
  final IconData icon;

  /// The main of the fact, when the chip carries it.
  final String? value;

  /// The words of the fact, for the reader who wants to know more.
  final String tooltip;

  /// The colour of the chip, which tells the reader what kind of fact it is.
  final FactTone tone;

  const MetaChip({
    super.key,
    required this.icon,
    required this.tooltip,
    this.value,
    this.tone = FactTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = factToneColor(tone, theme.colorScheme);
    final words = value;

    final chip = Container(
      height: CompactTokens.chipBox,
      // A chip without words is a small square of its own; a chip that
      // carries a word takes the room the word needs and no more.
      width: words == null ? CompactTokens.chipBox : null,
      alignment: words == null ? Alignment.center : null,
      padding: words == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: CompactTokens.space8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CompactTokens.radius6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: CompactTokens.icon14, color: color),
          if (words != null) ...[
            const SizedBox(width: CompactTokens.space4),
            Text(
              words,
              style: CompactTypography.mono(
                theme.colorScheme.onSurface,
                size: CompactTypeScale.mark,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );

    return TuneTooltip(message: tooltip, child: chip);
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
/// The chip is two halves that belong together, the way the buttons of a
/// button group are one control: the wide half names the thing and the small
/// square half does something with it. The value itself stands in the
/// tooltip: a path and an address are longer than a line, so they are not
/// written out. The reader reads the whole value where the pointer rests on
/// the chip, and acts on it with a click on the square half.
///
/// Every chip of the app is such a group: a name half and, when the chip
/// carries an action, an action half. The name half wears the colour of the
/// class it belongs to, the action half wears the accent of the shell, so a
/// chip that needs no action stays in one colour.
class ChipGroup extends StatelessWidget {
  /// The icon that lets a reader recognise the thing at a glance.
  final IconData icon;

  /// The name of the thing, such as the path of the file.
  final String label;

  /// The value that the chip carries, too long to be written out.
  final String value;

  /// The mark of the action that the square half does.
  final IconData actionIcon;

  /// The words that name the action, for the screen reader.
  ///
  /// The card of the tooltip says the value; the screen reader says what the
  /// chip does, because a value on its own does not say that it can be taken.
  final String actionHint;

  /// The colour of the name half, which tells the reader what kind of thing
  /// the chip carries.
  final FactTone tone;

  /// What the square half does when the reader clicks it.
  final VoidCallback onAction;

  const ChipGroup({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.actionIcon,
    required this.actionHint,
    required this.onAction,
    this.tone = FactTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = factToneColor(tone, theme.colorScheme);
    final radius = BorderRadius.circular(CompactTokens.radius6);

    // The name takes the room and the square takes the rest: the chip is
    // read as the name of the thing, and the square is the action on it.
    final name = Container(
      height: CompactTokens.chipBox,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: CompactTokens.icon14, color: color),
          const SizedBox(width: CompactTokens.space4),
          Text(
            label,
            style: CompactTypography.mono(
              color,
              size: CompactTypeScale.mark,
              weight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );

    final action = InkWell(
      onTap: onAction,
      child: Container(
        width: CompactTokens.chipBox,
        height: CompactTokens.chipBox,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          border: Border(
            left: BorderSide(color: color.withValues(alpha: 0.24)),
          ),
        ),
        child: Icon(
          actionIcon,
          size: CompactTokens.icon14,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return TuneTooltip(
      message: value,
      label: actionHint,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(mainAxisSize: MainAxisSize.min, children: [name, action]),
      ),
    );
  }
}
