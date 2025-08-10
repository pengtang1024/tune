import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 主题接口
///
/// 定义了应用程序主题需要实现的方法
abstract class AppThemeInterface {
  /// 获取Material浅色主题
  ThemeData get lightTheme;

  /// 获取Material深色主题
  ThemeData get darkTheme;

  /// 获取Cupertino主题
  CupertinoThemeData get cupertinoTheme;

  /// 获取Web主题
  ThemeData get webTheme;
}