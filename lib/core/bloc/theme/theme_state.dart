import 'package:flutter/material.dart';

/// 主题状态基类
///
/// 所有主题相关的状态都应该继承此类。
abstract class ThemeState {}

/// 初始主题状态
///
/// Bloc的初始状态。
class ThemeInitial extends ThemeState {}

/// 主题更改状态
///
/// 当主题发生更改时的状态。
class ThemeChangedState extends ThemeState {
  /// 当前的主题模式
  final ThemeMode themeMode;

  /// 当前的主题名称
  final String themeName;

  /// 当前的字体家族
  final String fontFamily;

  /// 创建主题更改状态
  ///
  /// [themeMode] 当前的主题模式
  /// [themeName] 当前的主题名称
  /// [fontFamily] 当前的字体家族
  ThemeChangedState(this.themeMode, {required this.themeName, required this.fontFamily});
}
