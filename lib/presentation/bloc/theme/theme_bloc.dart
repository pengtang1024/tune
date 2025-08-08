import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/config/app_config.dart';
import 'package:tune/presentation/bloc/theme/theme_event.dart';
import 'package:tune/presentation/bloc/theme/theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeInitial()) {
    on<ThemeChangedEvent>(_onThemeChanged);
  }

  void _onThemeChanged(ThemeChangedEvent event, Emitter<ThemeState> emit) async {
    // 保存主题模式到共享偏好设置
    String themeModeString;
    switch (event.themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    
    await AppConfig.setThemeMode(themeModeString);
    
    // 发出新的主题状态
    emit(ThemeChangedState(event.themeMode, themeName: event.themeName));
  }
}