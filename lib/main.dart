import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/config/app_config.dart';
import 'package:tune/config/theme/app_theme.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/presentation/bloc/localization/localization_bloc.dart';
import 'package:tune/presentation/bloc/localization/localization_state.dart';
import 'package:tune/presentation/bloc/theme/theme_bloc.dart';
import 'package:tune/presentation/bloc/theme/theme_state.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/core/routes/app_router.dart';
import 'dart:developer';

void main() async {
  // 确保WidgetsBinding初始化完成
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化依赖注入
  await DependencyInjection.init();

  // 初始化应用配置
  await AppConfig.init();

  FlutterError.onError = (details) {
    // 自定义错误处理（如上报到日志服务）
    log('生产环境错误: ${details.exception}');
  };

  // 运行应用
  runApp(const MyApp());
}

/// 应用程序主类
///
/// 这是应用程序的入口点，负责初始化和配置整个应用程序。
/// 它使用MultiBlocProvider来管理应用程序的状态，
/// 并根据用户的主题和语言偏好来配置应用程序的外观和本地化设置。
class MyApp extends StatelessWidget {
  /// 创建应用程序实例
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();

    return MultiBlocProvider(
      providers: [
        // 提供主题Bloc
        BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
        // 提供本地化Bloc
        BlocProvider<LocalizationBloc>(create: (context) => LocalizationBloc()),
        // 提供PlayerBloc
        BlocProvider<PlayerBloc>(
          create: (context) => DependencyInjection.get<PlayerBloc>(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocalizationBloc, LocalizationState>(
                builder: (context, localizationState) {
                  // 使用AppTheme类中的方法处理主题
                  final appTheme = AppTheme.getTheme(
                    (themeState is ThemeChangedState)
                      ? themeState.themeName ?? AppConfig.theme
                      : AppConfig.theme
                  );

                  // 确定当前的主题模式
                  final themeMode = (themeState is ThemeChangedState)
                    ? themeState.themeMode
                    : ThemeMode.system;

                  // 确定当前的语言代码
                  final locale = (localizationState is LocalizationChangedState)
                    ? localizationState.locale
                    : AppConfig.locale;

                  // 构建应用程序
                  return MaterialApp.router(
                    // 设置标题
                    title: AppLocalizations.of(context)?.app_name ?? 'Tune',

                    // 设置主题
                    theme: appTheme.themeData,

                    // 设置暗黑主题
                    darkTheme: appTheme.darkThemeData,

                    // 设置主题模式
                    themeMode: themeMode,

                    // 设置本地化相关属性
                    localizationsDelegates: AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: Locale(locale),

                    // 设置路由
                    routerConfig: appRouter.config(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
