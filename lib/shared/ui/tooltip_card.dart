import 'package:flutter/material.dart';

/// The card every hint is painted on.
///
/// The look lives in [TooltipThemeData]; this function only turns it into a
/// widget. It is read where the card is painted, inside the overlay, so a
/// hint that is open while the theme changes takes the new card at once.
Widget buildTooltipCard(TooltipThemeData theme, String message) {
  final textStyle = theme.textStyle;

  return ConstrainedBox(
    constraints: theme.constraints ?? const BoxConstraints(),
    child: DefaultTextStyle(
      style: textStyle ?? const TextStyle(),
      textAlign: theme.textAlign,
      child: Container(
        decoration: theme.decoration,
        padding: theme.padding,
        margin: theme.margin,
        child: Center(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: Text.rich(
            TextSpan(text: message),
            style: textStyle,
            textAlign: theme.textAlign,
          ),
        ),
      ),
    ),
  );
}
