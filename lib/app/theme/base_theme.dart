import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'theme_interface.dart';
import 'web_theme.dart';
import 'theme_manager.dart';

/// 基础主题类
///
/// 所有具体主题类的基类，提供通用功能
abstract class BaseTheme implements AppThemeInterface {
  /// 字体家族
  final String fontFamily;

  /// 构造函数
  BaseTheme({required this.fontFamily});

  /// 获取Material浅色主题
  @override
  ThemeData get lightTheme {
    final baseTheme = createLightTheme();
    return WebTheme.createTheme(baseTheme);
  }

  /// 获取Material深色主题
  @override
  ThemeData get darkTheme {
    final baseTheme = createDarkTheme();
    return WebTheme.createTheme(baseTheme);
  }

  /// 获取Cupertino主题
  @override
  CupertinoThemeData get cupertinoTheme {
    return createCupertinoTheme();
  }

  /// 获取Web主题（与浅色主题相同，但添加了Web特定配置）
  @override
  ThemeData get webTheme {
    return lightTheme;
  }

  /// 创建浅色主题（子类需要实现）
  ThemeData createLightTheme();

  /// 创建深色主题（子类需要实现）
  ThemeData createDarkTheme();

  /// 创建Cupertino主题（子类需要实现）
  CupertinoThemeData createCupertinoTheme();
}