import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tune/core/config/font_constants.dart';

import 'theme_interface.dart';

/// 基础主题类
///
/// 所有具体主题类的基类，提供通用功能
abstract class BaseTheme implements AppThemeInterface {
  /// 构造函数
  BaseTheme({String? fontFamily, ThemeMode? themeMode}) {
    this.fontFamily = fontFamily ?? FontFamily.defaultFont.value;
    this.themeMode = themeMode ?? ThemeMode.system;
  }

  /// 获取Material主题
  @override
  ThemeData get materialTheme {
    return createMaterialTheme();
  }

  /// 获取Cupertino主题
  @override
  CupertinoThemeData get cupertinoTheme {
    return createCupertinoTheme();
  }

  /// 获取Web主题
  @override
  ThemeData get webTheme {
    return createWebTheme();
  }

  /// 构建主题数据
  ///
  /// 根据字体家族和主题模式构建主题数据
  @override
  ThemeData buildThemeData(String? fontFamily, ThemeMode? themeMode);

  /// 创建Material主题（子类需要实现）
  @override
  ThemeData createMaterialTheme();

  /// 创建Cupertino主题（子类需要实现）
  @override
  CupertinoThemeData createCupertinoTheme();

  /// 创建Web主题（子类需要实现）
  @override
  ThemeData createWebTheme();
}
