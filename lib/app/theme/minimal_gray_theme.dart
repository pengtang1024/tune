import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tune/app/theme/web_theme.dart';
import 'package:tune/core/config/font_constants.dart';

import 'base_theme.dart';
import 'cupertino_theme.dart';
import 'material_theme.dart';

/// 极简灰调主题
///
/// 以简洁的灰色调为主，营造极简、干净的视觉体验
class MinimalGrayTheme extends BaseTheme {
  @override
  late String fontFamily;

  @override
  late ThemeMode themeMode;

  /// 构造函数
  MinimalGrayTheme({String? fontFamily, ThemeMode? themeMode}) : super(fontFamily: fontFamily ?? FontFamily.defaultFont.value, themeMode: themeMode ?? ThemeMode.system);

  @override
  String get themeName => 'minimalGray';

  @override
  ThemeData createMaterialTheme() {
    return MaterialTheme.fromTheme(buildThemeData(fontFamily, themeMode));
  }

  @override
  CupertinoThemeData createCupertinoTheme() {
    return CupertinoThemeConfig.fromTheme(buildThemeData(fontFamily, themeMode));
  }

  @override
  ThemeData createWebTheme() {
    return WebTheme.fromTheme(buildThemeData(fontFamily, themeMode));
  }

  @override
  ThemeData buildThemeData(String? fontFamily, ThemeMode? themeMode) {
    // 浅色模式的详细配色方案
    final isLight = themeMode == ThemeMode.light;
    final primaryColor = isLight ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final onPrimary = isLight ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final secondary = isLight ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
    final onSecondary = isLight ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final tertiary = isLight ? const Color(0xFF93C5FD) : const Color(0xFF60A5FA);
    final onTertiary = isLight ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final surface = isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
    final onSurface = isLight ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final onSurfaceVariant = isLight ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB);

    final colorScheme = ColorScheme(
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: primaryColor,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      tertiary: tertiary,
      onTertiary: onTertiary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      error: isLight ? const Color(0xFFB91C1C) : const Color(0xFFFECACA),
      onError: isLight ? Colors.white : const Color(0xFF450A0A),
      surfaceVariant: isLight ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
      outline: isLight ? const Color(0xFF9CA3AF) : const Color(0xFF94A3B8),
      outlineVariant: isLight ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isLight ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
      onInverseSurface: isLight ? Colors.white : const Color(0xFF1F2937),
      inversePrimary: isLight ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      primaryColor: colorScheme.primary,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: TextTheme(
        bodySmall: TextStyle(fontSize: TextStyles.bodySmallFontSize, fontWeight: FontWeight.normal, fontFamily: fontFamily, color: colorScheme.onSurfaceVariant),
        bodyMedium: TextStyle(fontSize: TextStyles.bodyMediumFontSize, fontWeight: FontWeight.normal, fontFamily: fontFamily, color: colorScheme.onSurface),
        bodyLarge: TextStyle(fontSize: TextStyles.bodyLargeFontSize, fontWeight: FontWeight.normal, fontFamily: fontFamily, color: colorScheme.onSurface),
        titleSmall: TextStyle(fontSize: TextStyles.titleSmallFontSize, fontWeight: FontWeight.bold, fontFamily: fontFamily, color: colorScheme.onSurface),
        titleMedium: TextStyle(fontSize: TextStyles.titleMediumFontSize, fontWeight: FontWeight.bold, fontFamily: fontFamily, color: colorScheme.onSurface),
        titleLarge: TextStyle(fontSize: TextStyles.titleLargeFontSize, fontWeight: FontWeight.bold, fontFamily: fontFamily, color: colorScheme.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        titleTextStyle: TextStyle(fontSize: TextStyles.appBarTitleFontSize, fontWeight: FontWeight.bold, fontFamily: fontFamily, color: colorScheme.onPrimary),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontFamily: fontFamily),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: colorScheme.primary, width: 3)),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
      ),
      sliderTheme: SliderThemeData(activeTrackColor: colorScheme.primary, inactiveTrackColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.3), thumbColor: colorScheme.primary, overlayColor: colorScheme.primary.withValues(alpha: 0.12)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.onSurface, fontSize: 16),
        subtitleTextStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),
    );
  }
}
