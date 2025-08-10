import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/core/config/app_config.dart';
import 'package:tune/core/utils/platform_detector.dart';
import 'package:tune/features/home/presentation/bloc/localization/localization_bloc.dart';
import 'package:tune/features/home/presentation/bloc/localization/localization_state.dart';
import 'package:tune/features/home/presentation/bloc/theme/theme_bloc.dart';
import 'package:tune/features/home/presentation/bloc/theme/theme_state.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/app/theme/theme_manager.dart';

/// 应用根组件
class App extends StatelessWidget {
  /// 构造函数
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, localizationState) {
            // 确定当前的主题名称
            final themeName = (themeState is ThemeChangedState)
                ? themeState.themeName ?? AppConfig.getValidThemeName(AppConfig.theme)
                : AppConfig.getValidThemeName(AppConfig.theme);

            // 确定当前的字体
            final fontFamily = (themeState is ThemeChangedState)
                ? themeState.fontFamily?.value ?? AppConfig.fontFamily.value
                : AppConfig.fontFamily.value;

            // 确定当前的主题模式
            final themeMode = (themeState is ThemeChangedState)
                ? themeState.themeMode
                : AppConfig.themeMode;

            // 确定当前的语言代码
            final locale = (localizationState is LocalizationChangedState)
                ? localizationState.locale
                : AppConfig.locale;

            // 根据平台决定使用Material还是Cupertino
            final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

            final appRouter = AppRouter();

            // 构建应用程序
            if (isIOS) {
              // iOS平台使用CupertinoApp
              return CupertinoApp.router(
                // 设置路由
                routerConfig: appRouter.config(),

                // 设置标题
                title: AppLocalizations.of(context)!.app_name ,

                // 设置主题
                theme: ThemeManager.getCupertinoTheme(themeName, fontFamily),

                // 设置本地化相关属性
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale(locale),
              );
            } else {
              // 其他平台使用MaterialApp
              return MaterialApp.router(
                // 设置路由
                routerConfig: appRouter.config(),

                // 设置标题
                title: AppLocalizations.of(context)!.app_name ,

                // 设置主题
                theme: ThemeManager.getMaterialLightTheme(themeName, fontFamily),

                // 设置暗黑主题
                darkTheme: ThemeManager.getMaterialDarkTheme(themeName, fontFamily),

                // 设置主题模式
                themeMode: themeMode,

                // 设置本地化相关属性
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale(locale),
              );
            }
          },
        );
      },
    );
  }
}
