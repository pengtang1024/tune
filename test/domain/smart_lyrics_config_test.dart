import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_config.dart';

/// What the reader pasted for the smart pipeline (docs/smart-lyrics.md §7.1).
///
/// The app holds no key of its own: the default template is OpenAI with its
/// model names prefilled, so the one move left to the reader is pasting a
/// key — and the pipeline is on.
void main() {
  group('the smart lyrics config', () {
    test('ships with the local engine on — the pipeline runs out of the '
        'box', () {
      const config = SmartLyricsConfig();

      expect(config.presetId, 'openai');
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.asrModels, ['whisper-1']);
      expect(config.chatModel, 'gpt-4o-mini');
      expect(config.apiKey, isEmpty);
      expect(config.localModel, 'tiny',
          reason: 'the local vote answers without any key or cloud');
      expect(config.isConfigured, isTrue,
          reason: 'a key is for the cloud, not a toll gate — the local '
              'engine alone already makes the pipeline runnable');
    });

    test('a key pasted on the default template turns the pipeline on', () {
      const config = SmartLyricsConfig();

      final ready = config.copyWith(apiKey: ' sk-test ');

      expect(ready.isConfigured, isTrue);
    });

    test('a key of blanks is no key', () {
      // With the local engine off, a blank key leaves the cloud
      // unconfigured — a key of blanks never opens the cloud door.
      const config = SmartLyricsConfig(localModel: '');

      expect(config.copyWith(apiKey: '   ').isConfigured, isFalse);
      expect(config.copyWith(apiKey: 'sk-x').isConfigured, isTrue);
    });

    test('the Groq template prefills its own endpoint and models', () {
      final groq = SmartLyricsPreset.byId('groq');

      expect(groq.baseUrl, 'https://api.groq.com/openai/v1');
      expect(groq.asrModels, isNotEmpty);
      expect(groq.chatModel, isNotEmpty);
    });

    test('an unknown preset id falls back to the custom template', () {
      expect(SmartLyricsPreset.byId('nonsense').id, 'custom');
    });

    test('the config survives a json round trip', () {
      const config = SmartLyricsConfig(
        presetId: 'custom',
        baseUrl: 'https://my.endpoint/v1',
        apiKey: 'sk-test',
        asrModels: ['whisper-1', 'whisper-large-v3'],
        chatModel: 'gpt-4o',
        localModel: 'base',
        batchCloudBudget: 120,
      );

      final restored = SmartLyricsConfig.fromJson(config.toJson());

      expect(restored.presetId, 'custom');
      expect(restored.baseUrl, 'https://my.endpoint/v1');
      expect(restored.apiKey, 'sk-test');
      expect(restored.asrModels, ['whisper-1', 'whisper-large-v3']);
      expect(restored.chatModel, 'gpt-4o');
      expect(restored.localModel, 'base');
      expect(restored.batchCloudBudget, 120);
      expect(restored.gapCheckEnabled, isTrue);
      expect(restored.isConfigured, isTrue);
    });

    test('the library fills itself on by default', () {
      expect(const SmartLyricsConfig().autoFill, isTrue);
      expect(const SmartLyricsConfig(autoFill: false).autoFill, isFalse);
      final restored = SmartLyricsConfig.fromJson(
        const SmartLyricsConfig(autoFill: false).toJson(),
      );
      expect(restored.autoFill, isFalse);
    });

    test('the free check is on until the reader turns it off', () {
      expect(const SmartLyricsConfig().gapCheckEnabled, isTrue);
      expect(
        const SmartLyricsConfig(gapCheckEnabled: false).gapCheckEnabled,
        isFalse,
      );
    });

    test('a broken field falls back to the defaults of that field', () {
      final restored = SmartLyricsConfig.fromJson({
        'asrModels': 'not a list',
        'chatModel': 42,
        'localModel': 42,
      });

      expect(restored.asrModels, SmartLyricsConfig().asrModels);
      expect(restored.chatModel, SmartLyricsConfig().chatModel);
      expect(restored.localModel, SmartLyricsConfig().localModel);
    });

    test('the local channel ships on and the reader may turn it off', () {
      expect(const SmartLyricsConfig().localModel, 'tiny');
      expect(const SmartLyricsConfig(localModel: '').localModel, '');
      expect(
        const SmartLyricsConfig(localModel: 'base').localModel,
        'base',
      );
    });

    test('a comma-separated chat model line names several models', () {
      const config = SmartLyricsConfig(
        chatModel: 'gpt-4o-mini, deepseek-chat ,mimo-v2.6-flash',
      );

      expect(config.chatModelList, ['gpt-4o-mini', 'deepseek-chat', 'mimo-v2.6-flash']);
      expect(const SmartLyricsConfig(chatModel: '').chatModelList, isEmpty);
      expect(const SmartLyricsConfig().chatModelList, ['gpt-4o-mini'],
          reason: 'a single name behaves exactly as before');
    });
  });
}
