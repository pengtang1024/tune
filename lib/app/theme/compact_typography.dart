import 'package:flutter/material.dart';

/// The typefaces of the compact shell and the CJK families behind them.
///
/// Fraunces, Instrument Sans and JetBrains Mono ship Latin glyphs only, so a
/// Chinese interface finds no glyph to draw in those faces. Without a named
/// fallback the platform picks whatever font it likes and the designed look
/// of the shell disappears.
///
/// Noto Sans SC and Noto Serif SC ship with the app, so the Chinese text looks
/// the same on every machine instead of depending on the fonts a user happens
/// to have installed. Both are variable fonts: one file covers every weight,
/// so a bold heading is a real bold and not a smeared synthetic one. The
/// system CJK families stay in the list as a safety net for the rare glyph the
/// bundled faces do not carry.
///
/// Every style built here keeps its Latin face first and names the CJK
/// families after it: Latin text keeps the designed face, CJK text keeps a
/// matching one instead of an arbitrary system default.
abstract final class CompactTypography {
  /// Display face for headings and titles.
  static const String displayFamily = 'Fraunces';

  /// Face for interface text.
  static const String sansFamily = 'Instrument Sans';

  /// Face for timestamps, counts and small caps labels.
  static const String monoFamily = 'JetBrains Mono';

  /// Sans CJK families, tried in order.
  static const List<String> sansFallback = <String>[
    'Noto Sans SC',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'PingFang SC',
    'Microsoft YaHei',
    'sans-serif',
  ];

  /// Serif CJK families, tried in order.
  static const List<String> serifFallback = <String>[
    'Noto Serif SC',
    'Noto Serif CJK SC',
    'Source Han Serif SC',
    'Songti SC',
    'SimSun',
    'serif',
  ];

  /// Monospace CJK families, tried in order.
  static const List<String> monoFallback = <String>[
    'Noto Sans Mono CJK SC',
    'Noto Sans Mono CJK TC',
    ...sansFallback,
  ];

  /// Interface text.
  static TextStyle sans(
    Color color, {
    required double size,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: sansFamily,
      fontFamilyFallback: sansFallback,
      fontVariations: weightVariations(weight),
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );
  }

  /// The weight axis, pinned so a variable face lands on the exact weight.
  ///
  /// The engine matches a variable font by the named instances it happens to
  /// carry, and the CJK faces skip some steps, so a `w600` request can land on
  /// a `w500` instance. Pinning the axis keeps the weight that was asked for.
  static List<FontVariation> weightVariations(FontWeight weight) {
    return <FontVariation>[FontVariation('wght', weight.value.toDouble())];
  }

  /// The axis values the display face is drawn with.
  ///
  /// Fraunces is a variable font, and its default instance is the plain one:
  /// `SOFT=0` on a 9pt optical size, which is why the packaged face reads
  /// stiffer than the round cut the design is after. `SOFT=100` rounds the
  /// strokes and opens up the curves, `WONK=1` keeps the wonky alternates,
  /// and `opsz` follows the text size so a 38px heading gets display
  /// proportions instead of text ones.
  static List<FontVariation> displayVariations(
    double size,
    FontWeight weight,
  ) {
    return <FontVariation>[
      FontVariation('opsz', size.clamp(9, 144)),
      FontVariation('SOFT', 100),
      FontVariation('WONK', 1),
      FontVariation('wght', weight.value.toDouble()),
    ];
  }

  /// Display text.
  static TextStyle display(
    Color color, {
    required double size,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontFamilyFallback: serifFallback,
      fontVariations: displayVariations(size, weight),
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );
  }

  /// Timestamps, counts and small caps labels.
  static TextStyle mono(
    Color color, {
    required double size,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontVariations: weightVariations(weight),
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );
  }

  /// Rewrites [base] onto the display face and keeps its other metrics.
  ///
  /// The theme already picks the right face per text role; this only changes
  /// the role of a style that was taken from a different one.
  static TextStyle? asDisplay(
    TextStyle? base, {
    double? size,
    FontWeight? weight,
    double? letterSpacing,
    double? height,
  }) {
    return base?.copyWith(
      fontFamily: displayFamily,
      fontFamilyFallback: serifFallback,
      fontVariations: displayVariations(
        size ?? base.fontSize ?? 20,
        weight ?? base.fontWeight ?? FontWeight.w600,
      ),
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
