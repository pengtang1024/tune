import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/settings/presentation/source_health_weights_sheet.dart';
import 'package:tune/l10n/app_localizations.dart';

void main() {
  Widget app({required ValueChanged<SourceHealthWeights?> onResult}) {
    return MaterialApp(
      theme: CompactTheme.light,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showSourceHealthWeightsSheet(
                context,
                initial: SourceHealthWeights.defaults,
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('a preset applies the whole bundle and Done returns it',
      (tester) async {
    SourceHealthWeights? result;
    await tester.pumpWidget(app(onResult: (value) => result = value));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('健康度权重'), findsOneWidget);
    expect(find.text('平衡'), findsOneWidget);
    expect(find.text('能播优先'), findsOneWidget);
    expect(find.text('新鲜优先'), findsOneWidget);

    await tester.tap(find.text('能播优先'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(result, SourceHealthWeights.playableFirst);
  });

  testWidgets('a stepper changes one weight and the share follows',
      (tester) async {
    SourceHealthWeights? result;
    await tester.pumpWidget(app(onResult: (value) => result = value));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(
      result!.availability,
      SourceHealthWeights.defaults.availability + 1,
    );
  });

  testWidgets('the sheet fits the smallest window at 1.3', (tester) async {
    tester.view.physicalSize = const Size(760, 520);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app(onResult: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('健康度权重'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
