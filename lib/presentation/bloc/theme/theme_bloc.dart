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
  ThemeBloc() : super(ThemeChangedState(ThemeMode.system)) {
    on<ThemeChangedEvent>((event, emit) async {
      // 保存主题设置到本地存储
      if (event.themeName != null) {
        await AppConfig.setTheme(event.themeName!);
      }

      // 发出新的主题状态
      emit(ThemeChangedState(event.themeMode, themeName: event.themeName));
    });
  }
}
