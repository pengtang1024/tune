import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// An action of a dense list row.
///
/// A page button carries a Material button, an input pad and a shape of its
/// own; a table row cannot pay for that eight times over. This primitive
/// keeps the parts a reader actually uses on a row — the ink, the hover, the
/// focus, Enter and Space, the semantic button — and drops the page-sized
/// box around them.
///
/// It is only for rows that are already dense. A page keeps its [IconButton].
class DenseIconAction extends StatelessWidget {
  /// The mark of the action.
  final IconData icon;

  /// The words the pointer and the screen reader say.
  final String tooltip;

  /// What the action does. A null action is disabled.
  final VoidCallback? onPressed;

  /// The colour of the mark, when the action carries a state of its own.
  final Color? color;

  /// The square the action keeps.
  final double size;

  /// The size of the mark inside the square.
  final double iconSize;

  /// Whether the action says a state, such as a heart that is filled.
  final bool selected;

  const DenseIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size = CompactTokens.libraryRowAction,
    this.iconSize = CompactTokens.icon16,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final markColor = enabled
        ? (color ?? theme.colorScheme.onSurfaceVariant)
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return TuneTooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected ? true : null,
        child: InkResponse(
          onTap: onPressed,
          canRequestFocus: enabled,
          focusColor: theme.colorScheme.primary.withValues(alpha: 0.16),
          hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          radius: size / 2,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: iconSize, color: markColor),
          ),
        ),
      ),
    );
  }
}
