import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tune/config/app_config.dart';
import 'package:tune/config/theme/app_theme.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:tune/core/routes/app_router.dart';
import 'package:tune/core/utils/localization_service.dart';
import 'package:tune/core/utils/localization_delegate.dart';
import 'package:tune/presentation/bloc/theme/theme_bloc.dart';
import 'package:tune/presentation/bloc/theme/theme_state.dart';
import 'package:tune/presentation/bloc/user/user_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Hive
  await Hive.initFlutter();
  
  // 初始化依赖注入
  await DependencyInjection.init();
  
  // 初始化应用配置
  await AppConfig.init();
  
  // 初始化本地化服务
  await LocalizationService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ThemeBloc(),
        ),
        BlocProvider(
          create: (_) => UserBloc(),
        ),
        BlocProvider(
          create: (_) => DependencyInjection().getPlayerBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          // 根据主题状态选择主题
          ThemeData? selectedTheme;
          if (state is ThemeChangedState) {
            switch (state.themeName) {
              case 'vibrant':
                selectedTheme = AppTheme.vibrantTheme;
                break;
              case 'vinyl':
                selectedTheme = AppTheme.vinylTheme;
                break;
              case 'tech':
                selectedTheme = AppTheme.techTheme;
                break;
              default:
                // 使用默认主题
                break;
            }
          }
          
          return MaterialApp.router(
            title: 'Tune',
            theme: selectedTheme ?? AppTheme.lightTheme,
            darkTheme: selectedTheme ?? AppTheme.darkTheme,
            themeMode: state is ThemeChangedState ? state.themeMode : ThemeMode.system,
            routerConfig: AppRouter().config(),
            debugShowCheckedModeBanner: false,
            
            // 本地化配置
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LocalizationService()
                .getSupportedLocales()
                .map((code) => Locale(code))
                .toList(),
            locale: Locale(LocalizationService().getCurrentLocale()),
          );
        },
      ),
    );
  }
}