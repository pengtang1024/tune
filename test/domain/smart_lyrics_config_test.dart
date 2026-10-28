import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_config.dart';

/// What the reader pasted for the smart pipeline (docs/smart-lyrics.md §7.1).
///
/// The app holds no key of its own: the default template is OpenAI with its
/// model names prefilled, so the one move left to the reader is pasting a
/// key — and the pipeline is on.
void main() {
  group('the smart lyrics config', () {
    test('defaults to the OpenAI template that waits only for a key', () {
      const config = SmartLyricsConfig();

      expect(config.presetId, 'openai');
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.asrModels, ['whisper-1']);
      expect(config.chatModel, 'gpt-4o-mini');
      expect(config.apiKey, isEmpty);
      expect(config.isConfigured, isFalse, reason: 'no key yet');
    });

    test('a key pasted on the default template turns the pipeline on', () {
      const config = SmartLyricsConfig();

      final ready = config.copyWith(apiKey: ' sk-test ');

      expect(ready.isConfigured, isTrue);
    });

    test('a key of blanks is no key', () {
      const config = SmartLyricsConfig();

      expect(config.copyWith(apiKey: '   ').isConfigured, isFalse);
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

    test('the local channel is off until a model is named', () {
      expect(const SmartLyricsConfig().localModel, '');
      expect(
        const SmartLyricsConfig(localModel: 'base').localModel,
        'base',
      );
    });
  });
}
