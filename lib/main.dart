import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/config/app_initializer.dart';
import 'package:tune/ui/core/layout/providers/app_bar_providers.dart';
import 'package:tune/providers/router_providers.dart';
import 'package:tune/config/app_theme.dart';

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
        // 监听主题模式变化
        final themeMode = ref.watch(themeModeProvider);
        // 监听语言环境变化
        final locale = ref.watch(localeProvider);

        return MaterialApp.router(
          title: 'Tune',
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: ref.watch(goRouterProvider),
          debugShowCheckedModeBanner: false,
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