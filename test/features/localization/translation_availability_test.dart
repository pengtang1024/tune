import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/translation/translation_assets.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/features/localization/application/local_model_controller.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/domain/settings_state.dart';

import '../../services/fake_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerFor(
    LocalizationConfig config, {
    List<Override> overrides = const [],
  }) {
    return ProviderContainer(
      overrides: [
        // The keys live outside the preferences document, so the settings of
        // the test are seeded straight into the controller.
        settingsControllerProvider.overrideWith(
          (ref) =>
              _SeededSettingsController(SettingsState(localization: config)),
        ),
        ...overrides,
      ],
    );
  }

  TranslationAvailability availabilityOf(LocalizationConfig config) {
    final container = containerFor(config);
    addTearDown(container.dispose);
    return container.read(translationAvailabilityProvider);
  }

  test('no vendor chosen asks for one', () {
    expect(
      availabilityOf(const LocalizationConfig()),
      TranslationAvailability.needsProvider,
    );
  });

  test('a hosted vendor without a key asks for the key', () {
    expect(
      availabilityOf(const LocalizationConfig(backendId: 'deepseek')),
      TranslationAvailability.needsKey,
    );
  });

  test('a local proxy may go without a key', () {
    expect(
      availabilityOf(const LocalizationConfig(backendId: 'ollama')),
      TranslationAvailability.available,
    );
  });

  test('the custom entry needs its endpoint', () {
    expect(
      availabilityOf(const LocalizationConfig(backendId: 'custom')),
      TranslationAvailability.needsProvider,
    );
  });

  test('a key and a model make the vendor available', () {
    final config = const LocalizationConfig(backendId: 'deepseek')
        .withCredential(
          'deepseek',
          const ProviderCredential(
            apiKey: 'sk-deepseek',
            model: 'deepseek-chat',
          ),
        );

    expect(availabilityOf(config), TranslationAvailability.available);
  });

  test('the bundled model that is not installed is reported missing', () async {
    final temp = await Directory.systemTemp.createTemp('tune-local-model');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final container = containerFor(
      const LocalizationConfig(backendId: LocalizationConfig.localBackendId),
      overrides: [
        translationAssetsProvider.overrideWith(
          (ref) async =>
              TranslationAssets(Directory(temp.path), supportPath: temp.path),
        ),
        localModelControllerProvider.overrideWith(
          (ref) => LocalModelController(
            resolveAssets: () => ref.watch(translationAssetsProvider.future),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Both providers are auto-disposed; keep them alive while the first
    // check of the empty directory runs.
    container.listen(localModelControllerProvider, (_, _) {});
    container.listen(translationAvailabilityProvider, (_, _) {});

    await _waitUntil(
      () =>
          container.read(localModelControllerProvider).phase !=
          LocalModelPhase.checking,
    );

    expect(
      container.read(localModelControllerProvider).phase,
      LocalModelPhase.notInstalled,
    );
    expect(
      container.read(translationAvailabilityProvider),
      TranslationAvailability.localNotInstalled,
    );
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 400; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('the local model check did not finish');
}

/// A controller that starts from the settings of the test.
class _SeededSettingsController extends SettingsController {
  _SeededSettingsController(SettingsState initial)
    : super(FakePersistenceService()) {
    state = initial;
  }
}
