import 'package:flutter/material.dart';

/// 主题事件基类
///
/// 所有主题相关的事件都应该继承此类。
abstract class ThemeEvent {}

/// 主题更改事件
///
/// 当用户选择新的主题时触发此事件。
class ThemeChangedEvent extends ThemeEvent {
  /// 新的主题模式
  final ThemeMode themeMode;

  /// 新的主题名称
  final String themeName;

  /// 创建主题更改事件
  ///
  /// [themeMode] 新的主题模式
  /// [themeName] 新的主题名称
  ThemeChangedEvent(this.themeMode, this.themeName);
}

/// 字体家族更改事件
///
/// 当用户选择新的字体时触发此事件。
class FontFamilyChangedEvent extends ThemeEvent {
  /// 新的字体家族
  final String fontFamily;

  /// 创建字体家族更改事件
  ///
  /// [fontFamily] 新的字体家族
  FontFamilyChangedEvent(this.fontFamily);
}
