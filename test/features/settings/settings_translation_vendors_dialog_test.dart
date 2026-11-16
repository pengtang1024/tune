import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/translation/translation_key_store.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_translation_vendors_dialog.dart';
import 'package:tune/l10n/app_localizations.dart';

import '../../services/fake_persistence.dart';

class _MemoryKeyStore extends TranslationKeyStore {
  @override
  Map<String, String> get keys => {};

  @override
  Future<void> init() async {}

  @override
  Future<void> write(Map<String, String> keys) async {}
}

/// The vendor page: search over the catalog, per-kind groups, and the detail
/// panel that owns the fields of the chosen service.
void main() {
  Future<SettingsController> pumpDialog(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = SettingsController(
      FakePersistenceService(),
      keyStore: _MemoryKeyStore(),
    );
    // The page must not stop on the privacy dialog in these tests.
    await controller.setLocalization(
      const LocalizationConfig(enabled: false, privacyAccepted: true),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith((ref) => controller),
          providerModelsProvider.overrideWith(
            (ref, query) => Future.value(const <String>[]),
          ),
          translationBalanceProvider.overrideWith((ref) => Future.value(null)),
          activeTranslationModelProvider.overrideWithValue(
            LocalComponentRegistry.translationModel,
          ),
          localComponentStateProvider.overrideWith(
            (ref, id) => const LocalComponentState(LocalComponentPhase.checking),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTranslationVendorsDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(
      find.byKey(const ValueKey('translation-vendors-search')),
      query,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the list groups plans before metered keys, local and custom', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(
      find.byKey(const ValueKey('translation-vendors-group-subscription')),
      findsOneWidget,
      reason: 'plans come first',
    );
    expect(
      find.byKey(const ValueKey('translation-vendors-group-api')),
      findsOneWidget,
    );
    expect(
      find.text('OpenCode Go'),
      findsOneWidget,
      reason: 'the subscription plan is in the catalog',
    );
    await search(tester, 'opencode zen');
    expect(find.text('OpenCode Zen'), findsOneWidget);

    await search(tester, 'bundled');
    expect(
      find.byKey(const ValueKey('translation-vendors-group-local')),
      findsOneWidget,
    );
    expect(find.text('本地模型（可选下载）'), findsOneWidget);

    await search(tester, 'custom');
    expect(
      find.byKey(const ValueKey('translation-vendors-group-custom')),
      findsOneWidget,
    );
    expect(find.text('自定义 OpenAI 兼容'), findsOneWidget);
  });

  testWidgets('the search narrows the catalog and says when nothing matches', (
    tester,
  ) async {
    await pumpDialog(tester);

    await search(tester, 'opencode');
    expect(find.text('OpenCode Go'), findsOneWidget);
    expect(find.text('OpenCode Zen'), findsOneWidget);
    expect(find.text('OpenAI'), findsNothing);

    await search(tester, 'no-such-vendor');
    expect(find.text('没有匹配的厂商'), findsOneWidget);
  });

  testWidgets('a plan vendor explains how it bills and keeps the fetch button', (
    tester,
  ) async {
    await pumpDialog(tester);

    await search(tester, 'opencode go');
    await tester.tap(
      find.byKey(const ValueKey('translation-vendor-opencode-go')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('按订阅套餐计费，用量以套餐额度为准。'),
      findsOneWidget,
      reason: 'a plan is not a metered key',
    );
    expect(find.widgetWithText(OutlinedButton, '获取模型'), findsOneWidget);
  });

  testWidgets('the custom entry edits its own base URL', (tester) async {
    final controller = await pumpDialog(tester);

    await search(tester, 'custom');
    await tester.tap(find.byKey(const ValueKey('translation-vendor-custom')));
    await tester.pumpAndSettle();

    final baseUrl = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == '端点（Base URL）',
    );
    await tester.enterText(baseUrl, 'https://proxy.example/v1');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(
      controller.state.localization.credentialFor('custom').baseUrl,
      'https://proxy.example/v1',
    );
    expect(controller.state.localization.backendId, 'custom');
  });
}
