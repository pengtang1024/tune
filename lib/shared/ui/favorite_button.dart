import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The heart that marks a track as one of the favorites.
///
/// The heart is a control and not a mark of a row: it says what it does.
/// A track that is liked carries a filled heart, a track that is not
/// carries an empty one, and the mouse says what a click will do.
class FavoriteButton extends StatelessWidget {
  final bool isFavorite;

  /// What the click does. A null button says "there is nothing to mark here",
  /// the way the other controls of the app say it.
  final VoidCallback? onPressed;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: isFavorite
          ? context.loc.favoriteRemove
          : context.loc.favoriteAdd,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: CompactTokens.icon18,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        style: IconButton.styleFrom(
          foregroundColor: isFavorite
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
