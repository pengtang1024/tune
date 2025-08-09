import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/config/app_config.dart';
import 'package:tune/presentation/bloc/theme/theme_event.dart';
import 'package:tune/presentation/bloc/theme/theme_state.dart';

/// 主题Bloc类
///
/// 负责管理应用程序的主题状态，处理主题更改事件，
/// 并将主题设置持久化到本地存储中。
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  /// 创建主题Bloc实例
  ///
  /// 初始化Bloc，设置初始状态为ThemeInitial，并注册事件处理器。
  ThemeBloc() : super(ThemeChangedState(AppConfig.themeMode, themeName: _getValidThemeName(AppConfig.theme))) {
    on<ThemeChangedEvent>((event, emit) async {
      final validThemeName = _getValidThemeName(event.themeName);
      
      // 保存主题设置到本地存储
      await AppConfig.setTheme(validThemeName);
      await AppConfig.setThemeMode(event.themeMode);

      // 发出新的主题状态
      emit(ThemeChangedState(event.themeMode, themeName: validThemeName));
    });
    
    // 处理字体更改事件
    on<FontFamilyChangedEvent>((event, emit) async {
      // 保存字体设置到本地存储
      await AppConfig.setFontFamily(event.fontFamily);
      
      // 重新发出当前主题状态以触发UI重建
      if (state is ThemeChangedState) {
        final currentState = state as ThemeChangedState;
        emit(ThemeChangedState(currentState.themeMode, themeName: currentState.themeName));
      }
    });
  }
  
  /// 验证并返回有效的主题名称
  /// 
  /// 如果提供的主题名称无效或为null，则返回默认主题名称
  static String _getValidThemeName(String? themeName) {
    // 有效的主题列表
    const validThemes = [
      'trendyElectro',
      'minimalGray', 
      'natureForest',
      'cyberNeon',
      'warmHealing'
    ];
    
    // 如果主题名称有效，直接返回
    if (themeName != null && validThemes.contains(themeName)) {
      return themeName;
    }
    
    // 否则返回默认主题
    return 'trendyElectro';
  }
}