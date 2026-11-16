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

  test('every vendor but the custom and local entries names an endpoint', () {
    for (final provider in translationProviderCatalog) {
      if (provider.id == 'custom' || provider.id == 'local') continue;
      expect(
        provider.baseUrl.trim(),
        isNotEmpty,
        reason: '${provider.id} needs an endpoint',
      );
    }
  });

  test('the balance endpoints sit under the versioned API root', () {
    // Both vendors answer 404 without the `/v1` prefix.
    expect(
      providerById('moonshot')!.balance!.url,
      'https://api.moonshot.cn/v1/users/me/balance',
    );
    expect(
      providerById('siliconflow')!.balance!.url,
      'https://api.siliconflow.cn/v1/user/info',
    );
  });

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

  test('a vendor without a model-list endpoint says so', () {
    // Zhipu's API reference carries no list endpoint, so the page must not
    // offer a button that can only fail.
    expect(providerById('zhipu')!.listsModels, isFalse);
    expect(providerById('openai')!.listsModels, isTrue);
    expect(providerById('custom')!.listsModels, isTrue);
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
