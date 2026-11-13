import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/localization_config.dart';

void main() {
  group('LocalizationConfig', () {
    test('starts on, with no vendor and no credentials', () {
      const config = LocalizationConfig();
      expect(config.backendId, isEmpty);
      expect(config.credentials, isEmpty);
      expect(config.enabled, isTrue);
      expect(config.showOriginal, isTrue);
      expect(config.privacyAccepted, isFalse);
      expect(config.hasBackend, isFalse);
    });

    test('migrates the old offline engine', () {
      final config = LocalizationConfig.fromJson({'engine': 'local'});

      expect(config.backendId, LocalizationConfig.localBackendId);
      expect(config.credentials, isEmpty);
      expect(config.usesLocalModel, isTrue);
    });

    test('migrates the old single endpoint into the custom vendor', () {
      final config = LocalizationConfig.fromJson({
        'engine': 'openAiCompatible',
        'apiBaseUrl': 'https://api.example.com/v1',
        'apiKey': 'secret',
        'apiModel': 'model',
      });

      expect(config.backendId, LocalizationConfig.customBackendId);
      expect(config.isCustom, isTrue);
      expect(config.activeCredential.apiKey, 'secret');
      expect(config.activeCredential.model, 'model');
      expect(config.activeCredential.baseUrl, 'https://api.example.com/v1');
    });

    test('every vendor keeps its model and endpoint through the store', () {
      final config = const LocalizationConfig(backendId: 'deepseek')
          .withCredential(
            'deepseek',
            const ProviderCredential(model: 'deepseek-chat'),
          )
          .withCredential(
            'custom',
            const ProviderCredential(
              model: 'custom-model',
              baseUrl: 'https://api.example.com/v1',
            ),
          );

      final restored = LocalizationConfig.fromJson(config.toJson());

      expect(restored, config);
      expect(restored.credentialFor('deepseek').model, 'deepseek-chat');
      expect(restored.credentialFor('custom').model, 'custom-model');
      expect(
        restored.credentialFor('custom').baseUrl,
        'https://api.example.com/v1',
      );
    });

    test('credentials written by hand are read back', () {
      final config = LocalizationConfig.fromJson({
        'backendId': 'deepseek',
        'credentials': {
          'deepseek': {
            'apiKey': 'sk-deepseek',
            'model': 'deepseek-chat',
            'baseUrl': '',
          },
        },
      });

      expect(config.activeCredential.apiKey, 'sk-deepseek');
      expect(config.activeCredential.model, 'deepseek-chat');
    });

    test('switching the vendor keeps the other vendors', () {
      final config = const LocalizationConfig(backendId: 'deepseek')
          .withCredential(
            'deepseek',
            const ProviderCredential(
              apiKey: 'sk-deepseek',
              model: 'deepseek-chat',
            ),
          )
          .withCredential(
            'moonshot',
            const ProviderCredential(
              apiKey: 'sk-moonshot',
              model: 'kimi-latest',
            ),
          );

      final switched = config.copyWith(backendId: 'moonshot');

      expect(switched.activeCredential.apiKey, 'sk-moonshot');
      expect(switched.activeCredential.model, 'kimi-latest');
      expect(switched.credentialFor('deepseek').apiKey, 'sk-deepseek');
      expect(switched.credentialFor('deepseek').model, 'deepseek-chat');
      expect(switched == config, isFalse);
    });

    test('a copy without changes equals the original', () {
      final config = const LocalizationConfig(
        backendId: 'openai',
      ).withCredential('openai', const ProviderCredential(apiKey: 'sk'));

      expect(config.copyWith(), config);
      expect(config.copyWith().hashCode, config.hashCode);
    });

    test('credential order does not change equality', () {
      const deepseek = ProviderCredential(apiKey: 'a', model: 'm');
      const moonshot = ProviderCredential(apiKey: 'b', model: 'n');
      final first = const LocalizationConfig(backendId: 'deepseek')
          .withCredential('deepseek', deepseek)
          .withCredential('moonshot', moonshot);
      final second = const LocalizationConfig(backendId: 'deepseek')
          .withCredential('moonshot', moonshot)
          .withCredential('deepseek', deepseek);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
