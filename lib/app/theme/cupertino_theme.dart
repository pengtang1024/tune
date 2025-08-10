import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Cupertino主题配置
///
/// 为iOS平台提供Cupertino风格的主题
class CupertinoThemeConfig {
  /// 创建Cupertino主题
  static CupertinoThemeData createTheme({
    required Color primaryColor,
    required String? fontFamily,
  }) {
    return CupertinoThemeData(
      primaryColor: primaryColor,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(fontFamily: fontFamily),
      ),
    );
  }

  /// 转换Material主题为Cupertino主题
  static CupertinoThemeData fromMaterialTheme(ThemeData materialTheme) {
    return CupertinoThemeData(
      primaryColor: materialTheme.primaryColor,
      scaffoldBackgroundColor: materialTheme.scaffoldBackgroundColor,
      textTheme: CupertinoTextThemeData(
        textStyle: materialTheme.textTheme.bodyMedium,
      ),
    );
  }
}