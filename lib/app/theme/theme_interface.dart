import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tune/core/config/font_constants.dart';

/// 主题接口
///
/// 定义了应用程序主题需要实现的方法
abstract class AppThemeInterface {
  /// 获取Material主题
  ThemeData get materialTheme;

  /// 获取Cupertino主题
  CupertinoThemeData get cupertinoTheme;

  /// 获取Web主题
  ThemeData get webTheme;

  /// 获取主题模式
  ThemeMode themeMode = ThemeMode.system;

  /// 获取主题名称
  String get themeName;

  /// 字体
  String fontFamily = FontFamily.defaultFont.value;

  /// 构建主题数据
  ///
  /// 根据字体家族和主题模式构建主题数据
  ThemeData buildThemeData(String? fontFamily, ThemeMode themeMode);

  /// 创建Material主题（子类需要实现）
  ThemeData createMaterialTheme();

  /// 创建Cupertino主题（子类需要实现）
  CupertinoThemeData createCupertinoTheme();

  /// 创建Web主题（子类需要实现）
  ThemeData createWebTheme();
}
