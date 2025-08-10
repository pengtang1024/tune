import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 应用主题配置类
///
/// 定义了应用程序的各种主题样式，包括颜色、字体、形状等设计元素。
/// 每个主题都遵循Material Design设计规范，并针对不同的视觉风格进行了定制。
class AppTheme {
  /// 创建带有指定字体系列的文本样式
  static TextStyle _createTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    String? fontFamily,
  }) {
    // 处理字体系列逻辑
    String? effectiveFontFamily;
    if (fontFamily == null || fontFamily == 'Default') {
      effectiveFontFamily = null; // 使用系统默认字体
    } else if (fontFamily.startsWith('JetBrainsMono')) {
      // 对于JetBrains Mono系列字体，使用统一字体系列名称
      effectiveFontFamily = 'JetBrainsMono';
    } else {
      effectiveFontFamily = fontFamily;
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: effectiveFontFamily,
    );
  }

  /// 潮流轻电主题 - 浅色模式
  static ThemeData getTrendyElectroTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFFC7D2FE), // 雾蓝紫
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFC7D2FE),
        onPrimary: Color(0xFF1E293B),
        secondary: Color(0xFFFBCFE8),
        onSecondary: Color(0xFF1E293B),
        tertiary: Color(0xFFBFDBFE),
        onTertiary: Color(0xFF1E293B),
        surface: Color(0xFFFAFAFC),
        onSurface: Color(0xFF1E293B),
        onSurfaceVariant: Color(0xFF64748B),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFC),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC7D2FE),
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
        fillColor: const Color(0xFFF1F5F9),
      ),
    );
  }

  /// 潮流轻电主题 - 深色模式
  static ThemeData getTrendyElectroDarkTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF4F46E5), // 深蓝紫
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4F46E5),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFFEC4899),
        onSecondary: Color(0xFFFFFFFF),
        tertiary: Color(0xFF3B82F6),
        onTertiary: Color(0xFFFFFFFF),
        surface: Color(0xFF0F172A),
        onSurface: Color(0xFFF1F5F9),
        onSurfaceVariant: Color(0xFF94A3B8),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF818CF8),
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
        fillColor: const Color(0xFF1E293B),
      ),
    );
  }

  /// 潮流轻电主题 - Cupertino风格
  static CupertinoThemeData getCupertinoTrendyElectroTheme(String fontFamily) {
    return CupertinoThemeData(
      primaryColor: const Color(0xFFC7D2FE),
      scaffoldBackgroundColor: const Color(0xFFFAFAFC),
      textTheme: CupertinoTextThemeData(
        textStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        navTitleTextStyle: _createTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        navLargeTitleTextStyle: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        actionTextStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  /// 极简灰主题 - 浅色模式
  static ThemeData getMinimalGrayTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF94A3B8), // 冷灰蓝
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF94A3B8),
        onPrimary: Color(0xFF1E293B),
        secondary: Color(0xFFCBD5E1),
        onSecondary: Color(0xFF1E293B),
        tertiary: Color(0xFF64748B),
        onTertiary: Color(0xFFFFFFFF),
        surface: Color(0xFFF8FAFC),
        onSurface: Color(0xFF0F172A),
        onSurfaceVariant: Color(0xFF475569),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF94A3B8),
          foregroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF94A3B8),
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
            color: Color(0xFF94A3B8),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFE2E8F0),
      ),
    );
  }

  /// 极简灰主题 - 深色模式
  static ThemeData getMinimalGrayDarkTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF475569), // 深灰蓝
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF475569),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF334155),
        onSecondary: Color(0xFFFFFFFF),
        tertiary: Color(0xFF64748B),
        onTertiary: Color(0xFFFFFFFF),
        surface: const Color(0xFF0F172A),
        onSurface: const Color(0xFFF1F5F9),
        onSurfaceVariant: const Color(0xFF94A3B8),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF475569),
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF94A3B8),
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
            color: Color(0xFF475569),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF1E293B),
      ),
    );
  }

  /// 极简灰主题 - Cupertino风格
  static CupertinoThemeData getCupertinoMinimalGrayTheme(String fontFamily) {
    return CupertinoThemeData(
      primaryColor: const Color(0xFF94A3B8),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: CupertinoTextThemeData(
        textStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        navTitleTextStyle: _createTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        navLargeTitleTextStyle: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        actionTextStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  /// 自然森林主题 - 浅色模式
  static ThemeData getNatureForestTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF84CC16), // 鲜绿
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF84CC16),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF4ADE80),
        onSecondary: Color(0xFFFFFFFF),
        tertiary: Color(0xFFA3E635),
        onTertiary: Color(0xFFFFFFFF),
        surface: const Color(0xFFF0FDF4),
        onSurface: const Color(0xFF052E16),
        onSurfaceVariant: const Color(0xFF166534),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0FDF4),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF84CC16),
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF84CC16),
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
            color: Color(0xFF84CC16),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFDCFCE7),
      ),
    );
  }

  /// 自然森林主题 - 深色模式
  static ThemeData getNatureForestDarkTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF4ADE80), // 亮绿
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4ADE80),
        onPrimary: Color(0xFF052E16),
        secondary: Color(0xFF22C55E),
        onSecondary: Color(0xFF052E16),
        tertiary: Color(0xFFA3E635),
        onTertiary: Color(0xFF052E16),
        surface: const Color(0xFF052E16),
        onSurface: const Color(0xFFD1FAE5),
        onSurfaceVariant: const Color(0xFF4ADE80),
      ),
      scaffoldBackgroundColor: const Color(0xFF052E16),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ADE80),
          foregroundColor: const Color(0xFF052E16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4ADE80),
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
            color: Color(0xFF4ADE80),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF064E3B),
      ),
    );
  }

  /// 自然森林主题 - Cupertino风格
  static CupertinoThemeData getCupertinoNatureForestTheme(String fontFamily) {
    return CupertinoThemeData(
      primaryColor: const Color(0xFF84CC16),
      scaffoldBackgroundColor: const Color(0xFFF0FDF4),
      textTheme: CupertinoTextThemeData(
        textStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        navTitleTextStyle: _createTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        navLargeTitleTextStyle: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        actionTextStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  /// 赛博霓虹主题 - 浅色模式
  static ThemeData getCyberNeonTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF3B82F6), // 亮蓝
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF3B82F6),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF8B5CF6),
        onSecondary: Color(0xFFFFFFFF),
        tertiary: Color(0xFF06B6D4),
        onTertiary: Color(0xFFFFFFFF),
        surface: const Color(0xFFE0F2FE),
        onSurface: const Color(0xFF0C4A6E),
        onSurfaceVariant: const Color(0xFF1E40AF),
      ),
      scaffoldBackgroundColor: const Color(0xFFE0F2FE),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF3B82F6),
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
            color: Color(0xFF3B82F6),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFBAE6FD),
      ),
    );
  }

  /// 赛博霓虹主题 - 深色模式
  static ThemeData getCyberNeonDarkTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1E40AF), // 暗蓝
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1E40AF),
        onPrimary: Color(0xFFF1F5F9),
        secondary: Color(0xFF7C3AED),
        onSecondary: Color(0xFFF1F5F9),
        tertiary: Color(0xFF06B6D4),
        onTertiary: Color(0xFFF1F5F9),
        surface: Color(0xFF0F172A),
        onSurface: Color(0xFFF1F5F9),
        onSurfaceVariant: Color(0xFF94A3B8),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF3B82F6),
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
            color: Color(0xFF1E40AF),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF1E293B),
      ),
    );
  }

  /// 赛博霓虹主题 - Cupertino风格
  static CupertinoThemeData getCupertinoCyberNeonTheme(String fontFamily) {
    return CupertinoThemeData(
      primaryColor: const Color(0xFF3B82F6),
      scaffoldBackgroundColor: const Color(0xFFE0F2FE),
      textTheme: CupertinoTextThemeData(
        textStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        navTitleTextStyle: _createTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        navLargeTitleTextStyle: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        actionTextStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  /// 暖心治愈主题 - 浅色模式
  static ThemeData getWarmHealingTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFFF97316), // 暖橙
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFF97316),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFFF59E0B),
        onSecondary: Color(0xFFFFFFFF),
        tertiary: Color(0xFFF43F5E),
        onTertiary: Color(0xFFFFFFFF),
        surface: const Color(0xFFFFF7ED),
        onSurface: const Color(0xFF7C2D12),
        onSurfaceVariant: const Color(0xFF9A3412),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF7ED),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: const Color(0xFFFFFFFF),
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
            color: Color(0xFFF97316),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFFED7AA),
      ),
    );
  }

  /// 暖心治愈主题 - 深色模式
  static ThemeData getWarmHealingDarkTheme(String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFEA580C), // 深暖橙
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFEA580C),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFFD97706),
        onSecondary: Color(0xFFFFFFFF),
        tertiary: Color(0xFFE11D48),
        onTertiary: Color(0xFFFFFFFF),
        surface: const Color(0xFF431407),
        onSurface: const Color(0xFFFED7AA),
        onSurfaceVariant: const Color(0xFFF97316),
      ),
      scaffoldBackgroundColor: const Color(0xFF431407),
      textTheme: TextTheme(
        bodySmall: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyMedium: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        bodyLarge: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        labelSmall: _createTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelMedium: _createTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        labelLarge: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        titleSmall: _createTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleMedium: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        titleLarge: _createTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineSmall: _createTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineMedium: _createTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        headlineLarge: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        displaySmall: _createTextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayMedium: _createTextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
        displayLarge: _createTextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          fontFamily: fontFamily,
        ),
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

  /// 暖心治愈主题 - Cupertino风格
  static CupertinoThemeData getCupertinoWarmHealingTheme(String fontFamily) {
    return CupertinoThemeData(
      primaryColor: const Color(0xFFF97316),
      scaffoldBackgroundColor: const Color(0xFFFFF7ED),
      textTheme: CupertinoTextThemeData(
        textStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
        navTitleTextStyle: _createTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        navLargeTitleTextStyle: _createTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        actionTextStyle: _createTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  /// 根据主题名称和字体获取对应的主题
  static ThemeData getTheme(String themeName, String fontFamily) {
    switch (themeName) {
      case 'minimalGray':
        return AppTheme.getMinimalGrayTheme(fontFamily);
      case 'natureForest':
        return AppTheme.getNatureForestTheme(fontFamily);
      case 'cyberNeon':
        return AppTheme.getCyberNeonTheme(fontFamily);
      case 'warmHealing':
        return AppTheme.getWarmHealingTheme(fontFamily);
      case 'trendyElectro':
      default:
        return AppTheme.getTrendyElectroTheme(fontFamily);
    }
  }

  /// 根据主题名称和字体获取对应的暗色主题
  static ThemeData getDarkTheme(String themeName, String fontFamily) {
    switch (themeName) {
      case 'minimalGray':
        return AppTheme.getMinimalGrayDarkTheme(fontFamily);
      case 'natureForest':
        return AppTheme.getNatureForestDarkTheme(fontFamily);
      case 'cyberNeon':
        return AppTheme.getCyberNeonDarkTheme(fontFamily);
      case 'warmHealing':
        return AppTheme.getWarmHealingDarkTheme(fontFamily);
      case 'trendyElectro':
      default:
        return AppTheme.getTrendyElectroDarkTheme(fontFamily);
    }
  }

  /// 根据主题名称和字体获取对应的Cupertino主题
  static CupertinoThemeData getCupertinoTheme(String themeName, String fontFamily) {
    switch (themeName) {
      case 'minimalGray':
        return AppTheme.getCupertinoMinimalGrayTheme(fontFamily);
      case 'natureForest':
        return AppTheme.getCupertinoNatureForestTheme(fontFamily);
      case 'cyberNeon':
        return AppTheme.getCupertinoCyberNeonTheme(fontFamily);
      case 'warmHealing':
        return AppTheme.getCupertinoWarmHealingTheme(fontFamily);
      case 'trendyElectro':
      default:
        return AppTheme.getCupertinoTrendyElectroTheme(fontFamily);
    }
  }
}