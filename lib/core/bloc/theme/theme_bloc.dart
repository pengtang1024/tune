import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/bloc/theme/theme_event.dart';
import 'package:tune/core/bloc/theme/theme_state.dart';
import 'package:tune/core/services/app_config_service.dart';

/// 主题Bloc类
///
/// 负责管理应用程序的主题状态，处理主题更改事件，
/// 并将主题设置持久化到本地存储中。
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  /// 创建主题Bloc实例
  ///
  /// 初始化Bloc，设置初始状态为ThemeInitial，并注册事件处理器。
  ThemeBloc() : super(_getInitialState()) {
    // 处理主题更改事件
    on<ThemeChangedEvent>((event, emit) async {
      final validThemeName = AppConfigService.getValidThemeName(event.themeName);

      // 保存主题设置到本地存储
      await AppConfigService.setTheme(validThemeName);
      await AppConfigService.setThemeMode(event.themeMode);

      // 发出新的主题状态
      emit(ThemeChangedState(event.themeMode, themeName: validThemeName, fontFamily: (state is ThemeChangedState) ? (state as ThemeChangedState).fontFamily : AppConfigService.fontFamily.value));
    });

    // 处理字体更改事件
    on<FontFamilyChangedEvent>((event, emit) async {
      // 保存字体设置到本地存储
      await AppConfigService.setFontFamily(event.fontFamily);

      // 获取当前主题状态，如果不存在则创建默认状态
      final currentState = state is ThemeChangedState ? state as ThemeChangedState : ThemeChangedState(AppConfigService.themeMode, themeName: AppConfigService.getValidThemeName(AppConfigService.theme), fontFamily: AppConfigService.fontFamily.value);

      // 发出新的主题状态，保留其他设置
      emit(ThemeChangedState(currentState.themeMode, themeName: currentState.themeName, fontFamily: event.fontFamily));
    });
  }

  /// 获取初始状态
  static ThemeState _getInitialState() {
    final initialThemeMode = AppConfigService.themeMode;
    final validThemeName = AppConfigService.getValidThemeName(AppConfigService.theme);
    final initialFontFamily = AppConfigService.fontFamily;

    return ThemeChangedState(initialThemeMode, themeName: validThemeName, fontFamily: initialFontFamily.value);
  }
}
