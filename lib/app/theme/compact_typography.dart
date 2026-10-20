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
/// to have installed. The system CJK families stay in the list as a safety net
/// for the rare glyph the bundled faces do not carry.
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
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );
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
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
