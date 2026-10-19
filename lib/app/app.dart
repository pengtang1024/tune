import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/config/app_initializer.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/localization_bridge.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/utils/logger.dart';

final appInitializationProvider = FutureProvider<void>((ref) async {
  await AppInitializer.initialize(ref);
  _scheduleStartupScan(ref);
});

/// Starts source scanning after the cached library is available.
///
/// The scan never blocks the first frame: the library controller already
/// serves cached songs while remote sources refresh in the background.
void _scheduleStartupScan(Ref ref) {
  final settings = ref.read(settingsControllerProvider);
  if (!settings.autoScanOnStartup) return;

  final localPaths = settings.effectiveScanPaths;
  Future<void>.microtask(() async {
    try {
      await ref.read(libraryControllerProvider.notifier).autoScan(localPaths);
    } catch (error, stackTrace) {
      Log.error('启动自动扫描失败: $error', stackTrace);
    }
  });
}

class TuneApp extends ConsumerWidget {
  const TuneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(appInitializationProvider);

    return initialization.when(
      data: (_) {
        final settings = ref.watch(settingsControllerProvider);
        final router = ref.watch(appRouterProvider);

        return MaterialApp.router(
          title: 'Tune',
          debugShowCheckedModeBanner: false,
          theme: CompactTheme.light,
          darkTheme: CompactTheme.dark,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            return LocalizationBridge(
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 1.0,
                maxScaleFactor: 1.3,
                child: child,
              ),
            );
          },
        );
      },
      loading: () => const _StartupScreen(),
      error: (error, stackTrace) {
        Log.error('应用启动失败: $error', stackTrace);
        return _StartupError(
          message: '$error',
          onRetry: () => ref.invalidate(appInitializationProvider),
        );
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CompactTheme.light,
      darkTheme: CompactTheme.dark,
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _StartupError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StartupError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CompactTheme.light,
      darkTheme: CompactTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 32),
                  const SizedBox(height: 12),
                  Text(context.loc.appStartFailed),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: Text(context.loc.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
