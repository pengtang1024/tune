import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'base_theme.dart';

/// 暖心治愈主题
///
/// 以温暖的橙色和粉色为主色，营造温暖、舒适的视觉效果
class WarmHealingTheme extends BaseTheme {
  /// 构造函数
  WarmHealingTheme({String fontFamily = 'Default'}) : super(fontFamily: fontFamily);

  @override
  ThemeData createLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFFF97316), // 暖橙
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFF97316), // 暖橙
        onPrimary: Color(0xFF374151), // 深灰
        secondary: Color(0xFFEC4899), // 粉红作为辅助色
        onSecondary: Color(0xFF374151), // 深灰
        tertiary: Color(0xFFF59E0B), // 金黄作为辅助色2
        onTertiary: Color(0xFF374151), // 深灰
        surface: Color(0xFFFFF7ED), // 浅米黄背景色
        onSurface: Color(0xFF374151), // 深灰文本主色
        onSurfaceVariant: Color(0xFF6B7280), // 中灰文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF7ED), // 页面底色
      textTheme: TextTheme(
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w900),
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w900),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEA580C), // 深暖橙
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFEA580C),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEA580C),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  @override
  ThemeData createDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFB45309), // 深棕
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB45309), // 深棕
        onPrimary: Color(0xFFFEF3C7), // 米黄
        secondary: Color(0xFFF59E0B), // 暖橙作为辅助色
        onSecondary: Color(0xFFFEF3C7), // 米黄
        tertiary: Color(0xFFEC4899), // 粉棕作为辅助色2
        onTertiary: Color(0xFFFEF3C7), // 米黄
        surface: Color(0xFF1F2937), // 深棕黑背景色
        onSurface: Color(0xFFFEF3C7), // 米黄文本主色
        onSurfaceVariant: Color(0xFFD1D5DB), // 浅灰文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFF1F2937), // 页面底色
      textTheme: TextTheme(
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w900),
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w900),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEA580C), // 深暖橙按钮点亮深色模式
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFF97316),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEA580C),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF78350F),
      ),
    );
  }

  @override
  CupertinoThemeData createCupertinoTheme() {
    return CupertinoThemeData(
      primaryColor: const Color(0xFFF97316),
      scaffoldBackgroundColor: const Color(0xFFFFF7ED),
      textTheme: CupertinoTextThemeData(
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        navTitleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        navLargeTitleTextStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        actionTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}