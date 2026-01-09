import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The [AppTheme] defines light and dark themes for the app.
///
/// Modern music player theme with vibrant colors and smooth gradients.
/// Enhanced visual experience with careful attention to typography,
/// spacing, and interactive elements.
abstract final class AppTheme {
  // Custom color palette for music app
  static const Color primaryViolet = Color(0xFF6B46C1);
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color surfaceDark = Color(0xFF0F0F0F);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF8FAFC);
  static const Color cardDark = Color(0xFF1A1A1A);

  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
    // Using custom color scheme for music app
    scheme: FlexScheme.deepPurple,
    colorScheme: const ColorScheme.light(
      primary: primaryViolet,
      secondary: accentPink,
      tertiary: accentBlue,
      surface: surfaceLight,
      surfaceContainer: cardLight,
      surfaceContainerHighest: Color(0xFFF1F5F9),
      inverseSurface: Color(0xFF1E293B),
      onSurface: Color(0xFF1E293B),
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFE2E8F0),
      outlineVariant: Color(0xFFF1F5F9),
    ),
    // Component theme configurations for light mode.
    subThemesData: const FlexSubThemesData(
      inputDecoratorIsFilled: true,
      alignedDropdown: true,
      tooltipRadius: 8,
      tooltipSchemeColor: SchemeColor.inverseSurface,
      tooltipOpacity: 0.95,
      snackBarElevation: 8,
      snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
      navigationRailUseIndicator: true,
      cardRadius: 12.0,
      cardElevation: 2.0,
      dialogRadius: 16.0,
      bottomSheetRadius: 20.0,
      inputDecoratorRadius: 12.0,
      chipRadius: 20.0,
      thickBorderWidth: 2.0,
      blendOnColors: true,
    ),
    // ColorScheme seed generation configuration for light mode.
    keyColors: const FlexKeyColors(
      useKeyColors: true,
      keepPrimary: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    // Enhanced typography
    textTheme: _buildTextTheme(Brightness.light),
    // Custom app bar theme is now set through subThemesData in newer FlexColorScheme versions
  ).copyWith(
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData dark = FlexThemeData.dark(
    // Using custom color scheme for music app
    scheme: FlexScheme.deepPurple,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: accentPink,
      tertiary: accentBlue,
      surface: surfaceDark,
      surfaceContainer: cardDark,
      surfaceContainerHighest: Color(0xFF262626),
      inverseSurface: Color(0xFFF8FAFC),
      onSurface: Color(0xFFF8FAFC),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF1E293B),
    ),
    // Component theme configurations for dark mode.
    subThemesData: const FlexSubThemesData(
      blendOnColors: true,
      inputDecoratorIsFilled: true,
      alignedDropdown: true,
      tooltipRadius: 8,
      tooltipSchemeColor: SchemeColor.inverseSurface,
      tooltipOpacity: 0.95,
      snackBarElevation: 8,
      snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
      navigationRailUseIndicator: true,
      cardRadius: 12.0,
      cardElevation: 2.0,
      dialogRadius: 16.0,
      bottomSheetRadius: 20.0,
      inputDecoratorRadius: 12.0,
      chipRadius: 20.0,
      thickBorderWidth: 2.0,
      useM2StyleDividerInM3: true,
    ),
    // ColorScheme seed configuration setup for dark mode.
    keyColors: const FlexKeyColors(
      useKeyColors: true,
      keepPrimary: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    // Enhanced typography
    textTheme: _buildTextTheme(Brightness.dark),
    // Custom app bar theme is now set through subThemesData in newer FlexColorScheme versions
  ).copyWith(
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // Build custom typography theme
  static TextTheme _buildTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.light 
        ? const Color(0xFF1E293B) 
        : const Color(0xFFF8FAFC);
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        color: textColor,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w300,
        color: textColor,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.31,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.27,
      ),
    );
  }
}
