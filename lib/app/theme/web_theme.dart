import 'package:flutter/material.dart';

/// Web端主题配置
///
/// 为Web平台提供特殊样式配置
class WebTheme {

  static ThemeData fromTheme(ThemeData buildThemeData) {
    return buildThemeData.copyWith(
      // Web端特殊配置
      scrollbarTheme: buildThemeData.scrollbarTheme.copyWith(thumbColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.5)), trackColor: WidgetStateProperty.all(Colors.transparent), trackBorderColor: WidgetStateProperty.all(Colors.transparent)),

      // Web端字体缩放
      textTheme: buildThemeData.textTheme.apply(fontSizeFactor: 1.0, fontSizeDelta: 0.0),
    );
  }
}
