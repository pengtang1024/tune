import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tune/app/theme/web_theme.dart';
import 'package:tune/core/config/font_constants.dart';

import 'base_theme.dart';
import 'cupertino_theme.dart';
import 'material_theme.dart';

/// 鲜艳红色主题
///
/// 以鲜艳的红色调为主，营造热情、活力的视觉体验
class VibrantRedTheme extends BaseTheme {
  @override
  late String fontFamily;

  @override
  late ThemeMode themeMode;

  /// 构造函数
  VibrantRedTheme({String? fontFamily, ThemeMode? themeMode}) : super(fontFamily: fontFamily, themeMode: themeMode) {
    this.fontFamily = fontFamily ?? FontFamily.defaultFont.value;
    this.themeMode = themeMode ?? ThemeMode.system;
  }

  @override
  String get themeName => 'vibrantRed';

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
    final isLight = themeMode == ThemeMode.light;
    
    // 浅色模式的详细配色方案
    final primaryColor = isLight ? const Color(0xFFEF4444) : const Color(0xFF7F1D1D);
    final onPrimary = isLight ? Colors.white : const Color(0xFFFFECEC);
    final secondary = isLight ? const Color(0xFFFECACA) : const Color(0xFFB91C1C);
    final onSecondary = isLight ? const Color(0xFF450A0A) : Colors.white;
    final tertiary = isLight ? const Color(0xFFFFECEC) : const Color(0xFFDC2626);
    final onTertiary = isLight ? const Color(0xFF450A0A) : Colors.white;
    final surface = isLight ? const Color(0xFFFFF5F5) : const Color(0xFF450A0A);
    final onSurface = isLight ? const Color(0xFF450A0A) : const Color(0xFFFFECEC);
    final onSurfaceVariant = isLight ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
    final surfaceContainerHighest = isLight ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D);

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
      inversePrimary: isLight ? const Color(0xFF7F1D1D) : const Color(0xFFEF4444),
      surfaceContainerHighest: surfaceContainerHighest,
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
        color: isLight 
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
        backgroundColor: isLight 
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
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary, 
        inactiveTrackColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.3), 
        thumbColor: colorScheme.primary, 
        overlayColor: colorScheme.primary.withValues(alpha: 0.12)
      ),
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
        tileColor: isLight 
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