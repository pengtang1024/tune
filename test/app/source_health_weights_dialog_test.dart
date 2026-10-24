import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/settings/presentation/source_health_weights_dialog.dart';
import 'package:tune/l10n/app_localizations.dart';

void main() {
  testWidgets('the health weights dialog saves the sliders', (tester) async {
    SourceHealthWeights? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<SourceHealthWeights>(
                  context: context,
                  builder: (context) => const SourceHealthWeightsDialog(
                    initial: SourceHealthWeights.defaults,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('健康度权重'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(12));
    expect(find.text('恢复默认'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.availability, SourceHealthWeights.defaults.availability);
    expect(result!.stability, SourceHealthWeights.defaults.stability);
  });

  testWidgets('the health weights dialog fits the smallest window at 1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 520);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<SourceHealthWeights>(
                context: context,
                builder: (context) => const SourceHealthWeightsDialog(
                  initial: SourceHealthWeights.defaults,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('健康度权重'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
