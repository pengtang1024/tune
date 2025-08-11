import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tune/app/theme/web_theme.dart';
import 'package:tune/core/config/font_constants.dart';

import 'base_theme.dart';
import 'cupertino_theme.dart';
import 'material_theme.dart';

/// 时尚电子主题
///
/// 以时尚的紫色调为主，营造现代电子感的视觉体验
class TrendyElectroTheme extends BaseTheme {
  @override
  late String fontFamily;

  @override
  late ThemeMode themeMode;

  /// 构造函数
  /// 构造函数
  TrendyElectroTheme({String? fontFamily, ThemeMode? themeMode}) : super(fontFamily: fontFamily, themeMode: themeMode) {
    this.fontFamily = fontFamily ?? FontFamily.defaultFont.value;
    this.themeMode = themeMode ?? ThemeMode.system;
  }

  @override
  String get themeName => 'trendyElectro';

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
      primary: themeMode == ThemeMode.light ? const Color(0xFF8B5CF6) : const Color(0xFFA78BFA),
      primaryContainer: themeMode == ThemeMode.light ? const Color(0xFF8B5CF6) : const Color(0xFFA78BFA),
      onPrimary: themeMode == ThemeMode.light ? Colors.white : const Color(0xFFEDE9FE),
      secondary: themeMode == ThemeMode.light ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6),
      onSecondary: themeMode == ThemeMode.light ? Colors.white : const Color(0xFFEDE9FE),
      tertiary: themeMode == ThemeMode.light ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6),
      onTertiary: themeMode == ThemeMode.light ? Colors.white : const Color(0xFFEDE9FE),
      surface: themeMode == ThemeMode.light ? const Color(0xFFEDE9FE) : const Color(0xFF5B21B6),
      onSurface: themeMode == ThemeMode.light ? const Color(0xFF5B21B6) : const Color(0xFFEDE9FE),
      onSurfaceVariant: themeMode == ThemeMode.light ? const Color(0xFF5B21B6) : const Color(0xFFEDE9FE),
      error: themeMode == ThemeMode.light ? const Color(0xFFB91C1C) : const Color(0xFFFECACA),
      onError: themeMode == ThemeMode.light ? Colors.white : const Color(0xFF450A0A),
      surfaceContainerHighest: themeMode == ThemeMode.light ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
      outline: themeMode == ThemeMode.light ? const Color(0xFF9CA3AF) : const Color(0xFF94A3B8),
      outlineVariant: themeMode == ThemeMode.light ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
      shadow: themeMode == ThemeMode.light ? Colors.black : Colors.transparent,
      scrim: themeMode == ThemeMode.light ? Colors.black : Colors.transparent,
      inverseSurface: themeMode == ThemeMode.light ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
      onInverseSurface: themeMode == ThemeMode.light ? Colors.white : const Color(0xFF1F2937),
      inversePrimary: themeMode == ThemeMode.light ? const Color(0xFF7C3AED) : const Color(0xFF8B5CF6),
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
        // 修改卡片颜色，使其与背景色有所区别
        color: themeMode == ThemeMode.light 
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7) 
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 4,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        // 修改底部导航栏背景色，使其与页面背景有所区别
        backgroundColor: themeMode == ThemeMode.light 
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8) 
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontFamily: fontFamily),
        elevation: 8,
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
        // 修改列表项背景色，增加组件间的区分度
        tileColor: themeMode == ThemeMode.light 
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) 
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.onSurface, fontSize: 16),
        subtitleTextStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.onSurfaceVariant, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}