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
class TuneTooltip extends StatelessWidget {
  /// The words of the hint.
  final String message;

  /// The thing the hint belongs to.
  final Widget child;

  /// Whether the hint opens below its thing instead of above it.
  ///
  /// Above is the better place on a desktop, where the pointer would cover a
  /// hint that opens below. A hint at the top of the window has no room
  /// above it, so it says [preferBelow] instead.
  final bool preferBelow;

  const TuneTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return child;

    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      child: child,
    );
  }
}
