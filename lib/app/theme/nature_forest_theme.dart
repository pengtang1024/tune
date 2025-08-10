import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'base_theme.dart';

/// 自然森林主题
///
/// 以绿色调为主，营造自然、清新和舒适的视觉体验
class NatureForestTheme extends BaseTheme {
  /// 构造函数
  NatureForestTheme({String fontFamily = 'Default'}) : super(fontFamily: fontFamily);

  @override
  ThemeData createLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF10B981), // 翠绿
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF10B981), // 翠绿
        onPrimary: Colors.white, // 白色
        secondary: Color(0xFF34D399), // 浅翠绿作为辅助色
        onSecondary: Colors.white, // 白色
        tertiary: Color(0xFF059669), // 深翠绿作为辅助色2
        onTertiary: Colors.white, // 白色
        surface: Color(0xFFF0FDF4), // 浅绿背景色
        onSurface: Color(0xFF065F46), // 深绿文本主色
        onSurfaceVariant: Color(0xFF047857), // 中绿文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFFF0FDF4), // 页面底色
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
          backgroundColor: const Color(0xFF059669), // 深翠绿
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF059669),
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
            color: Color(0xFF059669),
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
      primaryColor: const Color(0xFF34D399), // 浅翠绿
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF34D399), // 浅翠绿
        onPrimary: Color(0xFF065F46), // 深绿
        secondary: Color(0xFF6EE7B7), // 极浅翠绿作为辅助色
        onSecondary: Color(0xFF065F46), // 深绿
        tertiary: Color(0xFF10B981), // 翠绿作为辅助色2
        onTertiary: Color(0xFF065F46), // 深绿
        surface: Color(0xFF064E3B), // 深绿背景色
        onSurface: Color(0xFFD1FAE5), // 极浅绿文本主色
        onSurfaceVariant: Color(0xFF34D399), // 浅翠绿文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFF064E3B), // 页面底色
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
          backgroundColor: const Color(0xFF10B981), // 翠绿
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF34D399),
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
            color: Color(0xFF34D399),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF065F46),
      ),
    );
  }

  @override
  CupertinoThemeData createCupertinoTheme() {
    return CupertinoThemeData(
      primaryColor: const Color(0xFF10B981),
      scaffoldBackgroundColor: const Color(0xFFF0FDF4),
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