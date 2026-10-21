import 'package:flutter/material.dart';

/// The one tooltip of the app.
///
/// Every hint that is not written into the interface goes through this
/// widget, so the reader meets the same paper and ink wherever the pointer
/// rests. The look itself lives in the theme, this widget only decides when
/// there is a hint at all.
///
/// A tooltip without a message is no tooltip: the widget stays as it is and
/// nothing appears on the pointer. A sidebar that already writes the name of
/// a page does not say it twice.
///
/// The hint stands on [RawTooltip] and not on the [Tooltip] of the framework.
/// The framework paints the card of a hint once, when the hint opens, and
/// keeps that card until the hint closes, so a theme that changes while the
/// hint is on the screen would leave the old card on the screen. Here the
/// theme is read where the card is painted, inside the overlay of the hint,
/// so the hint takes the new theme with it.
class TuneTooltip extends StatelessWidget {
  /// The words of the hint.
  final String message;

  /// The thing the hint belongs to.
  final Widget child;

  /// The words the screen reader says for the hint.
  ///
  /// The card of the hint can say something else than the screen reader: a
  /// chip that carries an address shows the address on the card, while the
  /// screen reader says what the chip does. Without these words the card
  /// says both.
  final String? label;

  const TuneTooltip({
    super.key,
    required this.message,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return child;

    final theme = TooltipTheme.of(context);

    return RawTooltip(
      semanticsTooltip:
          theme.excludeFromSemantics == true ? null : (label ?? message),
      hoverDelay: theme.waitDuration ?? Duration.zero,
      touchDelay: theme.showDuration ?? const Duration(milliseconds: 1500),
      dismissDelay: theme.exitDuration ?? const Duration(milliseconds: 100),
      triggerMode: theme.triggerMode ?? TooltipTriggerMode.longPress,
      enableFeedback: theme.enableFeedback ?? true,
      // The card of the hint never takes the pointer, the way the tooltip of
      // the framework behaves when it carries words.
      ignorePointer: true,
      tooltipBuilder: (context, animation) {
        // The theme is read here, where the card is painted, and not out in
        // the widget tree. A card that reads the theme where it is painted
        // follows the theme at once, even while the hint is open.
        final theme = TooltipTheme.of(context);
        return FadeTransition(opacity: animation, child: _card(theme));
      },
      positionDelegate: (context) => positionDependentBox(
        size: context.overlaySize,
        childSize: context.tooltipSize,
        target: context.target,
        verticalOffset: theme.verticalOffset ?? 0,
        // Above the thing it belongs to, so the pointer never covers it. A
        // hint with no room above it says itself below, the way the frame
        // of the window allows it.
        preferBelow: theme.preferBelow ?? false,
      ),
      child: child,
    );
  }

  /// The card of the hint, in the look of the theme.
  Widget _card(TooltipThemeData theme) {
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
}
