import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tune/app/theme/web_theme.dart';
import 'package:tune/core/config/font_constants.dart';

import 'base_theme.dart';
import 'cupertino_theme.dart';
import 'material_theme.dart';

/// 自然森系主题
///
/// 以自然的绿色调为主，营造清新、舒适的视觉体验
class NatureForestTheme extends BaseTheme {


  /// 构造函数
  NatureForestTheme({String? fontFamily, ThemeMode? themeMode});
  @override
  late String fontFamily;

  @override
  late ThemeMode themeMode;
  @override
  String get themeName => 'natureForest';

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
    final primaryColor = isLight ? const Color(0xFFA7F3D0) : const Color(0xFF1E6B4E);
    final onPrimary = isLight ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4);
    final secondary = isLight ? const Color(0xFFDCFCE7) : const Color(0xFF065F46);
    final onSecondary = isLight ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4);
    final tertiary = isLight ? const Color(0xFFEFEBE9) : const Color(0xFF8B5A2B);
    final onTertiary = isLight ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4);
    final surface = isLight ? const Color(0xFFF0FDF4) : const Color(0xFF1E3A18);
    final onSurface = isLight ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4);
    final onSurfaceVariant = isLight ? const Color(0xFF64748B) : const Color(0xFFA1AEBD);
    final surfaceContainerHighest = isLight ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B);

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
      inversePrimary: isLight ? const Color(0xFF1E6B4E) : const Color(0xFFA7F3D0),
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