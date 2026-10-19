import 'package:flutter/material.dart';
import 'package:tune/config/app_theme.dart';

/// Theme entry point for the compact shell.
///
/// The base typography and color scheme are reused from [AppTheme]; this layer
/// only removes page-level decoration and tightens component defaults.
abstract final class CompactTheme {
  static ThemeData get light => _tune(AppTheme.light, Brightness.light);
  static ThemeData get dark => _tune(AppTheme.dark, Brightness.dark);

  static ThemeData _tune(ThemeData base, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF6F6F3);
    final surface = isDark ? const Color(0xFF1B1B1D) : Colors.white;

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: isDark ? const Color(0xFF2A2A2D) : const Color(0xFFE4E4E0),
      colorScheme: base.colorScheme.copyWith(
        surface: background,
        surfaceContainer: surface,
        surfaceContainerHighest: isDark
            ? const Color(0xFF262628)
            : const Color(0xFFEEEEE9),
        outlineVariant: isDark
            ? const Color(0xFF2A2A2D)
            : const Color(0xFFE4E4E0),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      tooltipTheme: base.tooltipTheme.copyWith(
        waitDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
