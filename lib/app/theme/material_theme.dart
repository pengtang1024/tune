import 'package:flutter/material.dart';

/// Material Design主题配置
///
/// 为移动和桌面平台提供统一的Material Design主题
class MaterialTheme {
  /// 创建Material Design主题
  static ThemeData createTheme({
    required Color primaryColor,
    required Color accentColor,
    required String? fontFamily,
  }) {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: accentColor,
      ),
      fontFamily: fontFamily,
      useMaterial3: true,
    );
  }

  /// 创建暗黑主题
  static ThemeData createDarkTheme({
    required Color primaryColor,
    required Color accentColor,
    required String? fontFamily,
  }) {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: accentColor,
        brightness: Brightness.dark,
      ),
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      useMaterial3: true,
    );
  }
}