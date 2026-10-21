import 'package:flutter/material.dart';

/// The room a measured box gets on top of the words it holds.
///
/// The painter reports the width of the words as a fraction, and the
/// paragraph that draws them asks for a hair more than that. A box that is
/// exactly as wide as the words breaks the last one onto a line of its own,
/// and a value that ends in a lonely letter looks like a mistake.
const double _room = 2;

/// The width of some words, as the painter that will draw them measures it.
///
/// The width is a little wider than the words, for the reason [_room] tells.
/// A box that is measured this way holds its words on one line.
double measureTextWidth(
  BuildContext context,
  String text,
  TextStyle? style, {
  int maxLines = 1,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines,
  )..layout();
  final width = painter.width;
  painter.dispose();

  return width + _room;
}
