import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'base_theme.dart';

/// 赛博朋克主题
///
/// 以霓虹色调为主，营造未来感和科技感的视觉体验
class CyberNeonTheme extends BaseTheme {
  /// 构造函数
  CyberNeonTheme({String fontFamily = 'Default'}) : super(fontFamily: fontFamily);

  @override
  ThemeData createLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF8B5CF6), // 紫色霓虹
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8B5CF6), // 紫色霓虹
        onPrimary: Colors.white, // 白色
        secondary: Color(0xFF06B6D4), // 青色霓虹作为辅助色
        onSecondary: Colors.white, // 白色
        tertiary: Color(0xFFEC4899), // 粉色霓虹作为辅助色2
        onTertiary: Colors.white, // 白色
        surface: Color(0xFFF5F3FF), // 浅紫背景色
        onSurface: Color(0xFF3730A3), // 深紫文本主色
        onSurfaceVariant: Color(0xFF7C3AED), // 中紫文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F3FF), // 页面底色
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
          backgroundColor: const Color(0xFF7C3AED), // 中紫
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF7C3AED),
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
            color: Color(0xFF7C3AED),
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
      primaryColor: const Color(0xFFA78BFA), // 浅紫霓虹
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFA78BFA), // 浅紫霓虹
        onPrimary: Color(0xFF312E81), // 深紫
        secondary: Color(0xFF22D3EE), // 浅青霓虹作为辅助色
        onSecondary: Color(0xFF312E81), // 深紫
        tertiary: Color(0xFFF472B6), // 浅粉霓虹作为辅助色2
        onTertiary: Color(0xFF312E81), // 深紫
        surface: Color(0xFF1E1B4B), // 深紫背景色
        onSurface: Color(0xFFEDE9FE), // 极浅紫文本主色
        onSurfaceVariant: Color(0xFFA78BFA), // 浅紫文本次色
      ),
      scaffoldBackgroundColor: const Color(0xFF1E1B4B), // 页面底色
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
          backgroundColor: const Color(0xFF8B5CF6), // 紫色霓虹
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFA78BFA),
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
            color: Color(0xFFA78BFA),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF312E81),
      ),
    );
  }

  @override
  CupertinoThemeData createCupertinoTheme() {
    return CupertinoThemeData(
      primaryColor: const Color(0xFF8B5CF6),
      scaffoldBackgroundColor: const Color(0xFFF5F3FF),
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