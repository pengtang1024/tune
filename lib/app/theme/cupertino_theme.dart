import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Cupertino主题配置
///
/// 为iOS平台提供Cupertino风格的主题
class CupertinoThemeConfig {
  /// 转换Material主题为Cupertino主题
  static CupertinoThemeData fromTheme(ThemeData materialTheme) {
    return CupertinoThemeData(
      brightness: materialTheme.brightness,
      primaryColor: materialTheme.primaryColor,
      primaryContrastingColor: materialTheme.primaryColorLight,
      barBackgroundColor: materialTheme.appBarTheme.backgroundColor,
      scaffoldBackgroundColor: materialTheme.scaffoldBackgroundColor,
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        textStyle: materialTheme.textTheme.bodyMedium,
        actionTextStyle: materialTheme.textTheme.labelLarge,
        tabLabelTextStyle: materialTheme.textTheme.labelLarge,
        navTitleTextStyle: materialTheme.textTheme.headlineSmall,
        navLargeTitleTextStyle: materialTheme.textTheme.headlineMedium,
        navActionTextStyle: materialTheme.textTheme.labelLarge,
      ),
    );
  }
}
