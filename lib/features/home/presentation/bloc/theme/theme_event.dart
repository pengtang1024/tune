import 'package:flutter/material.dart';
import 'package:tune/core/config/theme_config.dart';

/// 主题事件基类
///
/// 所有主题相关的事件都应该继承此类。
abstract class ThemeEvent {}

/// 主题更改事件
///
/// 当用户更改主题时触发此事件，包含新的主题模式和主题名称。
class ThemeChangedEvent extends ThemeEvent {
  /// 新的主题模式
  final ThemeMode themeMode;

  /// 新的主题名称
  final String? themeName;

  /// 创建主题更改事件实例
  ///
  /// [themeMode] 新的主题模式
  /// [themeName] 新的主题名称，可选
  ThemeChangedEvent(this.themeMode, {this.themeName});
}

/// 字体_family更改事件
///
/// 当用户更改字体时触发此事件，包含新的字体名称。
class FontFamilyChangedEvent extends ThemeEvent {
  /// 新的字体名称
  final AppFontFamily fontFamily;

  /// 创建字体更改事件实例
  ///
  /// [fontFamily] 新的字体名称
  FontFamilyChangedEvent(this.fontFamily);
}