import 'package:flutter/material.dart';

/// Web端主题配置
///
/// 为Web平台提供特殊样式配置
class WebTheme {
  /// 创建Web主题
  static ThemeData createTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      // Web端特殊配置
      scrollbarTheme: baseTheme.scrollbarTheme.copyWith(
        thumbColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.5)),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Web端字体缩放
      textTheme: baseTheme.textTheme.apply(
        fontSizeFactor: 1.0,
        fontSizeDelta: 0.0,
      ),
    );
  }
}