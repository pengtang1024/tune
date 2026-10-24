import 'package:flutter/material.dart';
import 'package:tune/shared/ui/hint_layer.dart';
import 'package:tune/shared/ui/hint_trigger.dart';
import 'package:tune/shared/ui/tooltip_card.dart';

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
/// Inside the app there is one [HintLayer] above the navigator. The trigger
/// only says which words belong to which rectangle; the layer owns the one
/// card and paints it in the overlay of the app, so a library row holds no
/// overlay of its own. A widget test that draws a tip without a layer falls
/// back to [RawTooltip], which keeps the standalone widget working.
///
/// The card is read where it is painted, inside the overlay, so a hint that
/// is open while the theme changes takes the new card at once.
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
    final label = theme.excludeFromSemantics == true
        ? null
        : (this.label ?? message);
    final wait = theme.waitDuration ?? Duration.zero;
    final touch = theme.showDuration ?? const Duration(milliseconds: 1500);
    final exit = theme.exitDuration ?? const Duration(milliseconds: 100);
    final preferBelow = theme.preferBelow ?? false;
    final verticalOffset = theme.verticalOffset ?? 0;
    final feedback = theme.enableFeedback ?? true;

    if (HintLayer.maybeOf(context) != null) {
      return HintTrigger(
        message: message,
        label: label,
        waitDuration: wait,
        visibleDuration: touch,
        exitDuration: exit,
        preferBelow: preferBelow,
        verticalOffset: verticalOffset,
        enableFeedback: feedback,
        child: child,
      );
    }

    return RawTooltip(
      semanticsTooltip: label,
      hoverDelay: wait,
      touchDelay: touch,
      dismissDelay: exit,
      triggerMode: theme.triggerMode ?? TooltipTriggerMode.longPress,
      enableFeedback: feedback,
      // The card of the hint never takes the pointer, the way the tooltip of
      // the framework behaves when it carries words.
      ignorePointer: true,
      tooltipBuilder: (context, animation) {
        // The theme is read here, where the card is painted, and not out in
        // the widget tree. A card that reads the theme where it is painted
        // follows the theme at once, even while the hint is open.
        final theme = TooltipTheme.of(context);
        return FadeTransition(
          opacity: animation,
          child: buildTooltipCard(theme, message),
        );
      },
      positionDelegate: (context) => positionDependentBox(
        size: context.overlaySize,
        childSize: context.tooltipSize,
        target: context.target,
        verticalOffset: verticalOffset,
        // Above the thing it belongs to, so the pointer never covers it. A
        // hint with no room above it says itself below, the way the frame
        // of the window allows it.
        preferBelow: preferBelow,
      ),
      child: child,
    );
  }
}
