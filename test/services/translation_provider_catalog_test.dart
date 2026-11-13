import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/translation/translation_provider_catalog.dart';
import 'package:tune/domain/models/translation_provider.dart';

void main() {
  test('every vendor has its own id', () {
    final ids = translationProviderCatalog
        .map((provider) => provider.id)
        .toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test(
    'every vendor but the custom and local entries names a default model',
    () {
      for (final provider in translationProviderCatalog) {
        if (provider.id == 'custom' || provider.id == 'local') continue;
        expect(
          provider.defaultModel.trim(),
          isNotEmpty,
          reason: '${provider.id} needs a starting model',
        );
      }
    },
  );

  test('the OpenAI-compatible vendors share the completions path', () {
    for (final provider in translationProviderCatalog) {
      if (provider.protocol != TranslationProtocol.openAiChat) continue;
      if (provider.isLocalModel) continue;
      expect(provider.chatPath, '/chat/completions', reason: provider.id);
    }
  });

  test('only the vendors that publish a balance report one', () {
    final withBalance = translationProviderCatalog
        .where((provider) => provider.supportsBalance)
        .map((provider) => provider.id)
        .toSet();

    expect(withBalance, {'deepseek', 'moonshot', 'openrouter', 'siliconflow'});
  });

  test('the flags tell the exceptions apart', () {
    expect(providerById('ollama')!.allowsEmptyKey, isTrue);
    expect(providerById('custom')!.isCustom, isTrue);
    expect(providerById('local')!.isLocalModel, isTrue);
    expect(providerById('deepseek')!.isCustom, isFalse);
    expect(providerById('deepseek')!.isLocalModel, isFalse);
  });

  test('an unknown id finds nothing', () {
    expect(providerById('nope'), isNull);
  });
}
