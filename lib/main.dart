import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/config/app_initializer.dart';
import 'package:tune/providers/theme_providers.dart';
import 'package:tune/providers/localization_providers.dart'; // 添加本地化提供者
import 'package:tune/routing/app_router.dart';
import 'package:tune/ui/core/themes/app_theme.dart';

import 'l10n/app_localizations.dart';

void main() async {
  // 确保WidgetsFlutterBinding初始化
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TuneApp()));
}

class TuneApp extends ConsumerWidget {
  const TuneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化应用（只在首次构建时调用）
    final initFuture = ref.watch(_initProvider);

    return initFuture.when(
      data: (_) {
        // 监听主题模式变化
        final themeMode = ref.watch(themeModeProvider);
        // 监听语言环境变化
        final locale = ref.watch(localeProvider);

        return MaterialApp.router(
          title: 'Tune',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: appRouter,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale, // 设置当前语言环境
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}

// 初始化提供者
final _initProvider = FutureProvider<void>((ref) async {
  await AppInitializer.init(ref);
});