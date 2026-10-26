import 'package:flutter/material.dart';

/// Draws the glyph of an icon font without the box of [Icon].
///
/// [Icon] wraps every mark in five elements: a semantic node, an exclusion
/// of that node, a square, a centre and the text itself. A dense row draws
/// six marks, and those wrappers cost more than the row's words. This
/// widget keeps the glyph, the font and the size, and leaves the box to the
/// caller that already has one.
///
/// The glyph is decoration: the control around it carries the name and the
/// hint. The empty semantic label says so, so a reader never hears the
/// private-use character of the font.
class IconGlyph extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  /// Whether the glyph gets a square of its own.
  ///
  /// A caller that already draws a square of the right size leaves this
  /// false; a mark that stands alone keeps the square [Icon] would have
  /// given it.
  final bool boxed;

  const IconGlyph(
    this.icon, {
    super.key,
    required this.size,
    this.color,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final theme = IconTheme.of(context);
    final style = TextStyle(
      inherit: false,
      color: color ?? theme.color,
      fontSize: size,
      fontFamily: icon.fontFamily,
      fontFamilyFallback: icon.fontFamilyFallback,
      package: icon.fontPackage,
      height: 1,
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
    );

    Widget glyph = RichText(
      textAlign: TextAlign.center,
      textDirection: direction,
      overflow: TextOverflow.visible,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        semanticsLabel: '',
        style: style,
      ),
    );

    if (icon.matchTextDirection && direction == TextDirection.rtl) {
      glyph = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scaleByDouble(-1, 1, 1, 1),
        child: glyph,
      );
    }

    if (!boxed) return glyph;
    return SizedBox.square(dimension: size, child: glyph);
  }
}
