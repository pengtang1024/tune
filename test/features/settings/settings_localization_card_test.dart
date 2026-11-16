import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/translation/translation_key_store.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_cache.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_localization_card.dart';
import 'package:tune/l10n/app_localizations.dart';

import '../../services/fake_persistence.dart';

/// The key file is real I/O, which the fake clock of a widget test never
/// settles; the card only needs the map the store keeps.
class _MemoryKeyStore extends TranslationKeyStore {
  final Map<String, String> saved = {};

  @override
  Map<String, String> get keys => saved;

  @override
  Future<void> init() async {}

  @override
  Future<void> write(Map<String, String> keys) async {
    saved
      ..clear()
      ..addAll(keys);
  }
}

/// The card of the translation settings: the vendor, its key and the models
/// the vendor itself reports.
void main() {
  Finder apiKeyField() => find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.labelText == 'API Key',
  );

  Finder modelField() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == '模型',
  );

  Finder balanceButton() =>
      find.ancestor(of: find.text('查询余额'), matching: find.byType(TextButton));

  Future<void> selectProvider(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<SettingsController> pumpCard(
    WidgetTester tester, {
    List<String> models = const [],
    void Function(ProviderModelQuery query)? onQuery,
    bool failModels = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1000, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = SettingsController(
      FakePersistenceService(),
      keyStore: _MemoryKeyStore(),
    );
    // The vendor tests do not walk the privacy dialog; the switch state is
    // the only thing this card reads from it.
    await controller.setLocalization(
      const LocalizationConfig(enabled: false, privacyAccepted: true),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith((ref) => controller),
          translationTokenUsageProvider.overrideWith(
            (ref) => Future.value(const TranslationTokenUsage()),
          ),
          translationCacheCountProvider.overrideWith((ref) => Future.value(0)),
          translationBalanceProvider.overrideWith((ref) => Future.value(null)),
          providerModelsProvider.overrideWith((ref, query) {
            onQuery?.call(query);
            if (failModels) {
              return Future<List<String>>.error(StateError('unreachable'));
            }
            return Future.value(models);
          }),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: SettingsLocalizationCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('nothing chosen shows the empty entry and the privacy note, '
      'and asks no server', (tester) async {
    var reads = 0;
    await pumpCard(tester, onQuery: (_) => reads++);

    expect(
      find.text('未配置'),
      findsOneWidget,
      reason: 'the picker starts on the empty entry',
    );
    expect(
      find.text('会发送哪些内容'),
      findsOneWidget,
      reason: 'the privacy note is always on the card',
    );
    expect(reads, 0, reason: 'no vendor chosen means no server is asked');
  });

  testWidgets('the balance button follows the vendor: off without an '
      'endpoint, on with one', (tester) async {
    await pumpCard(tester);

    await selectProvider(tester, 'OpenAI');
    expect(
      tester.widget<TextButton>(balanceButton()).onPressed,
      isNull,
      reason: 'OpenAI publishes no balance endpoint',
    );

    await selectProvider(tester, 'DeepSeek');
    expect(
      tester.widget<TextButton>(balanceButton()).onPressed,
      isNotNull,
      reason: 'DeepSeek publishes one',
    );
  });

  testWidgets('each vendor keeps its own key when the reader switches', (
    tester,
  ) async {
    final controller = await pumpCard(tester);

    await selectProvider(tester, 'DeepSeek');
    await tester.enterText(apiKeyField(), 'sk-deepseek');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    await selectProvider(tester, 'Moonshot / Kimi');
    await tester.enterText(apiKeyField(), 'sk-moonshot');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    await selectProvider(tester, 'DeepSeek');
    expect(
      tester.widget<TextField>(apiKeyField()).controller!.text,
      'sk-deepseek',
      reason: 'the field brings back the key of the chosen vendor',
    );
    expect(
      controller.state.localization.credentialFor('moonshot').apiKey,
      'sk-moonshot',
      reason: 'the other key stayed where it was',
    );
  });

  testWidgets('the fetch button reads the vendor models and the picker fills '
      'the field', (tester) async {
    await pumpCard(tester, models: const ['model-a', 'model-b']);

    await selectProvider(tester, 'OpenAI');
    await tester.tap(find.widgetWithText(OutlinedButton, '获取模型'));
    await tester.pumpAndSettle();

    expect(
      find.text('已获取 2 个模型'),
      findsOneWidget,
      reason: 'the count comes from the vendor, not a catalog',
    );

    await tester.tap(find.widgetWithText(TextButton, '选择模型'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'model-b'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(modelField()).controller!.text,
      'model-b',
      reason: 'the chosen model lands in the free-form field',
    );
  });

  testWidgets('the fetch sends the endpoint and key currently in the fields', (
    tester,
  ) async {
    ProviderModelQuery? seen;
    await pumpCard(
      tester,
      models: const ['deepseek-chat'],
      onQuery: (query) => seen = query,
    );

    await selectProvider(tester, 'DeepSeek');
    await tester.enterText(apiKeyField(), 'sk-now');
    await tester.tap(find.widgetWithText(OutlinedButton, '获取模型'));
    await tester.pumpAndSettle();

    expect(seen!.providerId, 'deepseek');
    expect(seen!.apiKey, 'sk-now');
    expect(
      seen!.baseUrl,
      isEmpty,
      reason: 'a catalog endpoint is used when the field is empty',
    );
  });

  testWidgets('a refused list says so and keeps the typed field', (
    tester,
  ) async {
    await pumpCard(tester, failModels: true);

    await selectProvider(tester, 'DeepSeek');
    await tester.enterText(modelField(), 'typed-model');
    await tester.tap(find.widgetWithText(OutlinedButton, '获取模型'));
    await tester.pumpAndSettle();

    expect(
      find.text('没有获取到模型，确认端点与密钥后重试，或直接填写模型名。'),
      findsOneWidget,
      reason: 'the page names the failure instead of showing nothing',
    );
    expect(
      tester.widget<TextField>(modelField()).controller!.text,
      'typed-model',
      reason: 'a failed fetch keeps what the reader typed',
    );
  });

  testWidgets('saving reads the models of the vendor just saved', (
    tester,
  ) async {
    var reads = 0;
    await pumpCard(tester, onQuery: (_) => reads++);

    await selectProvider(tester, 'OpenAI');
    await tester.enterText(apiKeyField(), 'sk-save');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(reads, 1, reason: 'saving is a natural moment to ask the vendor');
  });
}
