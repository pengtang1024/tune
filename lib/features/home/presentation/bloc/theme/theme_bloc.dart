import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/config/app_config.dart';
import 'package:tune/features/home/presentation/bloc/theme/theme_event.dart';
import 'package:tune/features/home/presentation/bloc/theme/theme_state.dart';

/// 主题Bloc类
///
/// 负责管理应用程序的主题状态，处理主题更改事件，
/// 并将主题设置持久化到本地存储中。
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  /// 创建主题Bloc实例
  ///
  /// 初始化Bloc，设置初始状态为ThemeInitial，并注册事件处理器。
  ThemeBloc() : super(ThemeInitial()) { // 使用ThemeInitial作为初始状态
    // 如果需要立即应用配置，可以在初始化时读取配置
    final initialThemeMode = AppConfig.themeMode;
    final validThemeName = AppConfig.getValidThemeName(AppConfig.theme);
    final initialFontFamily = AppConfig.fontFamily;

    // 初始化时使用ThemeChangedState
    emit(ThemeChangedState(
      initialThemeMode,
      themeName: validThemeName,
      fontFamily: initialFontFamily,
    ));

    // 处理主题更改事件
    on<ThemeChangedEvent>((event, emit) async {
      final validThemeName = AppConfig.getValidThemeName(event.themeName);

      // 保存主题设置到本地存储
      await AppConfig.setTheme(validThemeName);
      await AppConfig.setThemeMode(event.themeMode);

      // 发出新的主题状态
      emit(ThemeChangedState(
        event.themeMode,
        themeName: validThemeName,
        fontFamily: (state is ThemeChangedState)
            ? (state as ThemeChangedState).fontFamily
            : AppConfig.fontFamily,
      ));
    });

    // 处理字体更改事件 - 改进版本
    on<FontFamilyChangedEvent>((event, emit) async {
      // 保存字体设置到本地存储
      await AppConfig.setFontFamily(event.fontFamily);

      // 获取当前主题状态，如果不存在则创建默认状态
      final currentState = state is ThemeChangedState
          ? state as ThemeChangedState
          : ThemeChangedState(
              initialThemeMode,
              themeName: validThemeName,
              fontFamily: initialFontFamily,
            );

      // 发出新的主题状态以触发UI重建
      emit(ThemeChangedState(
        currentState.themeMode,
        themeName: currentState.themeName,
        fontFamily: event.fontFamily,
      ));
    });
  }
}
