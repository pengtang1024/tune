import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tune/app/theme/web_theme.dart';
import 'package:tune/core/config/font_constants.dart';

import 'base_theme.dart';
import 'cupertino_theme.dart';
import 'material_theme.dart';

/// 日落光辉主题
///
/// 以温暖的日落色调为主，营造温馨浪漫的视觉体验
class SunsetGlowTheme extends BaseTheme {
  @override
  late String fontFamily;

  @override
  late ThemeMode themeMode;

  /// 构造函数
  SunsetGlowTheme({String? fontFamily, ThemeMode? themeMode}) : super(fontFamily: fontFamily, themeMode: themeMode) {
    this.fontFamily = fontFamily ?? FontFamily.defaultFont.value;
    this.themeMode = themeMode ?? ThemeMode.system;
  }

  @override
  String get themeName => 'sunsetGlow';

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
    final colorScheme = ColorScheme(
      brightness: themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
      primary: themeMode == ThemeMode.light ? const Color(0xFFF97316) : const Color(0xFFEA580C),
      primaryContainer: themeMode == ThemeMode.light ? const Color(0xFFF97316) : const Color(0xFFEA580C),
      onPrimary: themeMode == ThemeMode.light ? Colors.white : const Color(0xFFFFF7ED),
      secondary: themeMode == ThemeMode.light ? const Color(0xFFEA580C) : const Color(0xFFF97316),
      onSecondary: themeMode == ThemeMode.light ? Colors.white : const Color(0xFFFFF7ED),
      tertiary: themeMode == ThemeMode.light ? const Color(0xFFEA580C) : const Color(0xFFF97316),
      onTertiary: themeMode == ThemeMode.light ? Colors.white : const Color(0xFFFFF7ED),
      surface: themeMode == ThemeMode.light ? const Color(0xFFFFF7ED) : const Color(0xFF9A3412),
      onSurface: themeMode == ThemeMode.light ? const Color(0xFF9A3412) : const Color(0xFFFFF7ED),
      onSurfaceVariant: themeMode == ThemeMode.light ? const Color(0xFF9A3412) : const Color(0xFFFFF7ED),
      error: themeMode == ThemeMode.light ? const Color(0xFFB91C1C) : const Color(0xFFFECACA),
      onError: themeMode == ThemeMode.light ? Colors.white : const Color(0xFF450A0A),
      surfaceContainerHighest: themeMode == ThemeMode.light ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
      outline: themeMode == ThemeMode.light ? const Color(0xFF9CA3AF) : const Color(0xFF94A3B8),
      outlineVariant: themeMode == ThemeMode.light ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
      shadow: themeMode == ThemeMode.light ? Colors.black : Colors.transparent,
      scrim: themeMode == ThemeMode.light ? Colors.black : Colors.transparent,
      inverseSurface: themeMode == ThemeMode.light ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
      onInverseSurface: themeMode == ThemeMode.light ? Colors.white : const Color(0xFF1F2937),
      inversePrimary: themeMode == ThemeMode.light ? const Color(0xFFEA580C) : const Color(0xFFF97316),
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