import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/app/theme/theme_manager.dart';
import 'package:tune/core/bloc/localization/localization_bloc.dart';
import 'package:tune/core/bloc/localization/localization_state.dart';
import 'package:tune/core/bloc/theme/theme_bloc.dart';
import 'package:tune/core/bloc/theme/theme_state.dart';
import 'package:tune/core/config/app_config.dart';
import 'package:tune/core/config/font_constants.dart';
import 'package:tune/l10n/app_localizations.dart';

/// 应用根组件
class App extends StatelessWidget {
  /// 构造函数
  const App({super.key, required this.appRouter});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, localizationState) {
            // 确定当前的主题名称
            final themeName = (themeState is ThemeChangedState) ? themeState.themeName : AppConfig.defaultTheme;

            // 确定当前的字体
            final fontFamily = (themeState is ThemeChangedState) ? themeState.fontFamily : FontFamily.defaultFont.value;

            // 确定当前的主题模式
            final themeMode = (themeState is ThemeChangedState) ? themeState.themeMode : ThemeMode.system;

            // 确定当前的语言代码
            final locale = (localizationState is LocalizationChangedState) ? localizationState.locale : AppConfig.defaultLocale;

            // 根据平台决定使用Material还是Cupertino
            final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

            // 获取应用标题，提供默认值以防本地化失败
            final appTitle = AppLocalizations.of(context)?.app_name ?? 'Tune';

            // 构建应用程序
            if (isIOS) {
              // iOS平台使用CupertinoApp
              return CupertinoApp.router(
                routerConfig: appRouter.config(),
                title: appTitle,
                debugShowCheckedModeBanner: false,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale(locale),
                theme: ThemeManager.getCupertinoTheme(themeName, fontFamily, themeMode),
                builder: (context, child) {
                  return GestureDetector(
                      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                      child: child ?? const SizedBox.shrink());
                },
              );
            } else {
              // 其他平台使用MaterialApp
              return MaterialApp.router(
                // 设置路由
                routerConfig: appRouter.config(),

                // 设置标题
                title: appTitle,

                // 设置主题
                theme: ThemeManager.getMaterialTheme(themeName, fontFamily, themeMode),
                darkTheme: ThemeManager.getMaterialTheme(themeName, fontFamily, themeMode),

                // 设置主题模式
                themeMode: themeMode,

                // 设置本地化相关属性
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale(locale),

                // 禁止显示调试横幅
                debugShowCheckedModeBanner: false,

                // 设置点击空白处取消焦点
                builder: (context, child) {
                  return GestureDetector(
                      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                      child: child ?? const SizedBox.shrink());
                },
              );
            }
          },
        );
      },
    );
  }
}
