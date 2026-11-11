import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// The translation on the main line and the original in small type below.
///
/// The widget is purely presentational: the caller resolves the translation,
/// so a row can rebuild on its own without this widget knowing about
/// providers or settings.
///
/// A name takes one line and keeps the original under it. A paragraph hands
/// in `null` for [maxLines] and [secondaryMaxLines]: the detail sheet writes
/// a whole description out, so both halves take the lines they need instead
/// of being squeezed into one.
class BilingualText extends StatelessWidget {
  final String primary;
  final String? secondary;
  final int? maxLines;
  final int? secondaryMaxLines;
  final TextStyle? primaryStyle;
  final TextStyle? secondaryStyle;
  final TextAlign? textAlign;
  final bool dense;

  /// Whether the lines may be selected and copied.
  ///
  /// The details sheet writes a description as selectable text, so a reader
  /// can take the words away; a row of a list stays plain text.
  final bool selectable;

  const BilingualText({
    super.key,
    required this.primary,
    required this.secondary,
    this.maxLines = 1,
    this.secondaryMaxLines = 1,
    this.primaryStyle,
    this.secondaryStyle,
    this.textAlign,
    this.dense = false,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final original = secondary?.trim();
    if (original == null || original.isEmpty || original == primary) {
      return _line(primary, maxLines, primaryStyle);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        _line(primary, maxLines, primaryStyle),
        SizedBox(height: dense ? 0 : CompactTokens.space4),
        _line(
          original,
          secondaryMaxLines,
          secondaryStyle ??
              theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _line(String value, int? lines, TextStyle? style) {
    if (selectable) {
      return SelectableText(
        value,
        maxLines: lines,
        textAlign: textAlign,
        style: style,
      );
    }
    return Text(
      value,
      maxLines: lines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: style,
    );
  }
}
