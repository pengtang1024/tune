import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 主题事件基类
/// 
/// 所有主题相关事件的基类，继承自Equatable以支持状态比较。
/// 通过实现props getter来定义事件的相等性比较。
abstract class ThemeEvent extends Equatable {
  /// 定义事件的相等性比较属性
  /// 
  /// 返回一个对象列表，用于比较事件是否相等。
  /// 空列表表示所有实例都相等。
  @override
  List<Object?> get props => [];
}

/// 主题更改事件
/// 
/// 当用户更改主题设置时触发的事件，包含新的主题模式和主题名称。
/// 该事件会被ThemeBloc处理以更新应用程序的主题。
class ThemeChangedEvent extends ThemeEvent {
  /// 新的主题模式（浅色、深色或系统默认）
  final ThemeMode themeMode;
  
  /// 新的主题名称（标识具体的主题样式）
  final String? themeName;

  /// 创建主题更改事件实例
  /// 
  /// [themeMode] 新的主题模式
  /// [themeName] 新的主题名称，可选参数
  ThemeChangedEvent(this.themeMode, {this.themeName});

  /// 定义事件的相等性比较属性
  /// 
  /// 包含themeMode和themeName，用于比较两个ThemeChangedEvent是否相等。
  @override
  List<Object?> get props => [themeMode, themeName];
}