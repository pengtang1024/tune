import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/localization/domain/localization_config.dart';

void main() {
  group('LocalizationConfig', () {
    test('starts on, offline, with the original under the translation', () {
      const config = LocalizationConfig();
      expect(config.enabled, isTrue);
      expect(config.showOriginal, isTrue);
      expect(config.engine, TranslationEngineKind.local);
      expect(config.apiConfigured, isFalse);
    });

    test('survives a round trip through the stored map', () {
      const config = LocalizationConfig(
        enabled: false,
        showOriginal: false,
        engine: TranslationEngineKind.openAiCompatible,
        apiBaseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        apiModel: 'model',
      );
      expect(LocalizationConfig.fromJson(config.toJson()), config);
    });

    test('an unknown engine falls back to the offline one', () {
      final config = LocalizationConfig.fromJson({
        'engine': 'someFutureEngine',
      });
      expect(config.engine, TranslationEngineKind.local);
    });

    test('an endpoint needs both a base url and a model', () {
      const urlOnly = LocalizationConfig(
        engine: TranslationEngineKind.openAiCompatible,
        apiBaseUrl: 'https://api.example.com/v1',
      );
      expect(urlOnly.apiConfigured, isFalse);
      expect(urlOnly.copyWith(apiModel: 'model').apiConfigured, isTrue);
    });
  });
}
