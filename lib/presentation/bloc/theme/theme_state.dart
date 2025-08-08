import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 主题状态基类
/// 
/// 所有主题相关状态的基类，继承自Equatable以支持状态比较。
/// 通过实现props getter来定义状态的相等性比较。
class ThemeState extends Equatable {
  /// 定义状态的相等性比较属性
  /// 
  /// 返回一个对象列表，用于比较状态是否相等。
  /// 空列表表示所有实例都相等。
  @override
  List<Object?> get props => [];
}

/// 初始主题状态
/// 
/// 应用程序启动时的默认主题状态。
class ThemeInitial extends ThemeState {}

/// 主题已更改状态
/// 
/// 当用户更改主题设置后，Bloc会发出此状态以通知UI更新。
/// 该状态包含当前的主题模式和主题名称。
class ThemeChangedState extends ThemeState {
  /// 当前的主题模式（浅色、深色或系统默认）
  final ThemeMode themeMode;
  
  /// 当前的主题名称（标识具体的主题样式）
  final String? themeName;

  /// 创建主题已更改状态实例
  /// 
  /// [themeMode] 当前的主题模式
  /// [themeName] 当前的主题名称，可选参数
  ThemeChangedState(this.themeMode, {this.themeName});

  /// 定义状态的相等性比较属性
  /// 
  /// 包含themeMode和themeName，用于比较两个ThemeChangedState是否相等。
  @override
  List<Object?> get props => [themeMode, themeName];
}