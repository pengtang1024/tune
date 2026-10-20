import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// The ring that says the app is busy.
///
/// The Material indicator is not used as it is. Its look draws the stroke
/// centred on the path, so half of the stroke falls outside of the box and
/// is cut away by the edge of the layer. The ring is then thick on the
/// diagonals and thin at the top, the bottom and the sides, and at the
/// small sizes the buttons use it turns into a rough polygon instead of a
/// circle.
///
/// The ring of the shell is drawn inside its own box, so the stroke keeps
/// the same width all the way around. The head of the arc is a round dot
/// rather than the hard square block of the Material look, which shows up
/// every time the arc shrinks to nothing, and the track behind the arc is
/// dropped because a second ring next to a small one only makes both of them
/// harder to read.
///
/// The three sizes cover the three places the shell waits: a page that is
/// still loading, a button that is still working and a control that sits
/// inside another one.
class CompactSpinner extends StatelessWidget {
  /// The ring of a control that sits inside another one.
  const CompactSpinner.small({super.key, this.color, this.value})
    : size = CompactTokens.spinnerSmall,
      strokeWidth = CompactTokens.spinnerStrokeSmall;

  /// The ring of a button of its own.
  const CompactSpinner.medium({super.key, this.color, this.value})
    : size = CompactTokens.spinnerMedium,
      strokeWidth = CompactTokens.spinnerStrokeMedium;

  /// The ring of a page that is still loading.
  const CompactSpinner.large({super.key, this.color, this.value})
    : size = CompactTokens.spinnerLarge,
      strokeWidth = CompactTokens.spinnerStrokeLarge;

  /// Diameter of the ring.
  final double size;

  /// Width of the stroke of the ring.
  final double strokeWidth;

  /// Colour of the ring; the accent of the theme when it is left out.
  final Color? color;

  /// How much of the ring is filled, or null for a ring that never ends.
  final double? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        strokeAlign: CircularProgressIndicator.strokeAlignInside,
        strokeCap: StrokeCap.round,
        color: color,
        value: value,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
