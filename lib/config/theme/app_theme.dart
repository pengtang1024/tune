import 'package:flutter/material.dart';

class AppTheme {
  // 活力律动主题（主打年轻潮流）
  static final ThemeData vibrantTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFD42A4A), // 深珊瑚红
      primary: const Color(0xFFD42A4A),
      onPrimary: Colors.white,
      secondary: const Color(0xFF4A90E2), // 天蓝
      onSecondary: Colors.white,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFD42A4A), // 深珊瑚红
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD42A4A), // 深珊瑚红
      foregroundColor: Colors.white,
    ),
  );

  // 沉浸黑胶主题（主打复古质感）
  static final ThemeData vinylTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D1F16), // 深棕黑
      primary: const Color(0xFF2D1F16),
      onPrimary: const Color(0xFFE0E0E0), // 象牙白
      secondary: const Color(0xFFC89040), // 古铜金
      onSecondary: Colors.black,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D1F16), // 深棕黑
      foregroundColor: Color(0xFFE0E0E0), // 象牙白
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFC89040), // 古铜金
      foregroundColor: Colors.black,
    ),
  );

  // 科技流光主题（主打未来感）
  static final ThemeData techTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0083B0), // 深海蓝
      primary: const Color(0xFF0083B0),
      onPrimary: const Color(0xFFECEFF1), // 浅灰蓝
      secondary: const Color(0xFF7B1FA2), // 深紫
      onSecondary: Colors.white,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0083B0), // 深海蓝
      foregroundColor: Color(0xFFECEFF1), // 浅灰蓝
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00B8D4), // 青蓝
      foregroundColor: Colors.black,
    ),
  );

  // 默认浅色主题
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6200EE),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6200EE),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF6200EE),
      foregroundColor: Colors.white,
    ),
  );

  // 默认深色主题
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFBB86FC),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF03DAC6),
      foregroundColor: Colors.black,
    ),
  );
}