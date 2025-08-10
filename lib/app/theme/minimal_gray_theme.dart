import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'base_theme.dart';

/// 最小化灰色主题
///
/// 以灰色调为主，提供简洁、专业和现代感的界面
class MinimalGrayTheme extends BaseTheme {
  /// 构造函数
  MinimalGrayTheme({String fontFamily = 'Default'}) : super(fontFamily: fontFamily);

  @override
  ThemeData createLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6B7280), // 中灰
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6B7280), // 中灰
        onPrimary: Colors.white, // 白色
        secondary: Color(0xFF9CA3AF), // 浅灰作为辅助色
        onSecondary: Colors.white, // 白色
        tertiary: Color(0xFF374151), // 深灰作为辅助色2
        onTertiary: Colors.white, // 白色
        surface: Color(0xFFF9FAFB), // 极浅灰背景色
        onSurface: Color(0xFF1F2937), // 深灰文本主色
        onSurfaceVariant: Color(0xFF6B7280), // 中灰文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB), // 页面底色
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
          backgroundColor: const Color(0xFF4B5563), // 灰蓝
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4B5563),
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
            color: Color(0xFF4B5563),
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
      primaryColor: const Color(0xFF9CA3AF), // 浅灰
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9CA3AF), // 浅灰
        onPrimary: Color(0xFF1F2937), // 深灰
        secondary: Color(0xFFD1D5DB), // 极浅灰作为辅助色
        onSecondary: Color(0xFF1F2937), // 深灰
        tertiary: Color(0xFF6B7280), // 中灰作为辅助色2
        onTertiary: Color(0xFF1F2937), // 深灰
        surface: Color(0xFF111827), // 极深灰背景色
        onSurface: Color(0xFFF9FAFB), // 极浅灰文本主色
        onSurfaceVariant: Color(0xFF9CA3AF), // 浅灰文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFF111827), // 页面底色
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
          backgroundColor: const Color(0xFF6B7280), // 中灰
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF9CA3AF),
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
            color: Color(0xFF9CA3AF),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF1F2937),
      ),
    );
  }

  @override
  CupertinoThemeData createCupertinoTheme() {
    return CupertinoThemeData(
      primaryColor: const Color(0xFF6B7280),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
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