import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/config/app_initializer.dart';
import 'package:tune/config/app_theme.dart';
import 'package:tune/core/router/app_router.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/utils/logger.dart';

import 'l10n/app_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: const TuneApp(),
    ),
  );
}

class TuneApp extends ConsumerWidget {
  const TuneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化应用（只在首次构建时调用）
    final initFuture = ref.watch(_initProvider);

    return initFuture.when(
      data: (_) {
        // 监听AppBar状态变化，包括主题和语言
        final appBarState = ref.watch(appBarStateNotifierProvider);
        Log.info("当前主题模式: ${appBarState.themeMode}");

        final router = ref.watch(routerProvider);

        return MaterialApp.router(
          title: 'Tune',
          themeMode: appBarState.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          locale: appBarState.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) {
        Log.error('应用启动失败: $error', stack);
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'Error occurred: $error',
              ),
            ),
          ),
        );
      },
    );
  }
}

// 初始化提供者
final _initProvider = FutureProvider<void>((ref) async {
  await AppInitializer.initialize(ref);
});