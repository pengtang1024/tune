import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'base_theme.dart';

/// 潮流轻电主题
///
/// 以科技感的电光蓝为主色，搭配简洁的白色背景，营造现代、潮流的视觉效果
class TrendyElectroTheme extends BaseTheme {
  /// 构造函数
  TrendyElectroTheme({String fontFamily = 'Default'}) : super(fontFamily: fontFamily);

  @override
  ThemeData createLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFFC7D2FE), // 雾蓝紫
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFC7D2FE), // 雾蓝紫
        onPrimary: Color(0xFF1E293B), // 深灰蓝
        secondary: Color(0xFFFBCFE8), // 柔粉作为辅助色
        onSecondary: Color(0xFF1E293B), // 深灰蓝
        tertiary: Color(0xFFBFDBFE), // 浅蓝作为辅助色2
        onTertiary: Color(0xFF1E293B), // 深灰蓝
        surface: Color(0xFFFAFAFC), // 极浅灰背景色
        onSurface: Color(0xFF1E293B), // 深灰蓝文本主色
        onSurfaceVariant: Color(0xFF64748B), // 灰蓝文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFC), // 页面底色
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
          backgroundColor: const Color(0xFF4F46E5), // 电光蓝
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4F46E5),
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
            color: Color(0xFF4F46E5),
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
      primaryColor: const Color(0xFF4F46E5), // 电光蓝
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4F46E5), // 电光蓝
        onPrimary: Color(0xFFFAFAFC), // 极浅灰
        secondary: Color(0xFFEC4899), // 粉紫作为辅助色
        onSecondary: Color(0xFFFAFAFC), // 极浅灰
        tertiary: Color(0xFF60A5FA), // 天蓝作为辅助色2
        onTertiary: Color(0xFFFAFAFC), // 极浅灰
        surface: Color(0xFF1E293B), // 深灰蓝背景色
        onSurface: Color(0xFFFAFAFC), // 极浅灰文本主色
        onSurfaceVariant: Color(0xFF94A3B8), // 浅灰蓝文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFF1E293B), // 页面底色
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
          backgroundColor: const Color(0xFFC7D2FE), // 雾蓝紫
          foregroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFC7D2FE),
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
            color: Color(0xFFC7D2FE),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF334155),
      ),
    );
  }

  @override
  CupertinoThemeData createCupertinoTheme() {
    return CupertinoThemeData(
      primaryColor: const Color(0xFF4F46E5),
      scaffoldBackgroundColor: const Color(0xFFFAFAFC),
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