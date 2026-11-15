import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';

/// The component registry is the one list of what can be downloaded. An
/// entry must say which platforms can actually use it, or a phone would be
/// offered a desktop binary that can never run (docs/android.md E5).
void main() {
  test('the in-app whisper model is an Android component only', () {
    final spec = LocalComponentRegistry.whisperOnnxModelSmall;

    expect(spec.supports(AppPlatform.android), isTrue);
    expect(spec.supports(AppPlatform.linux), isFalse);
    expect(spec.supports(AppPlatform.windows), isFalse);
    expect(spec.requiredFiles, hasLength(3));
    expect(
      spec.files.map((file) => file.fileName),
      containsAll([
        'small-encoder.int8.onnx',
        'small-decoder.int8.onnx',
        'small-tokens.txt',
      ]),
    );
  });

  test('desktop binaries are not offered on a phone', () {
    expect(
      LocalComponentRegistry.sherpaRuntime.supports(AppPlatform.android),
      isFalse,
    );
    expect(
      LocalComponentRegistry.whisperRuntime.supports(AppPlatform.android),
      isFalse,
    );
    for (final model in LocalComponentRegistry.whisperModels) {
      expect(model.supports(AppPlatform.android), isFalse);
    }
    expect(
      LocalComponentRegistry.ffmpeg.supports(AppPlatform.android),
      isFalse,
    );
  });

  test('the model folders the phone reads stay available on Android', () {
    for (final spec in [
      LocalComponentRegistry.sensevoiceModel,
      LocalComponentRegistry.funasrNanoModel,
    ]) {
      expect(spec.supports(AppPlatform.android), isTrue);
      expect(spec.supports(AppPlatform.linux), isTrue);
    }
  });

  test('the desktop list keeps every entry it had', () {
    final desktop = [
      for (final spec in LocalComponentRegistry.all)
        if (spec.supports(AppPlatform.linux)) spec.id,
    ];

    expect(desktop, isNot(contains('lyrics-whisper-onnx-model-small')));
    expect(desktop, contains('lyrics-sherpa-runtime'));
    expect(desktop, contains('lyrics-whisper-model-small'));
    expect(
      LocalComponentRegistry.all.where(
        (spec) => spec.id == 'lyrics-whisper-onnx-model-small',
      ),
      hasLength(1),
    );
  });

  test('a platform only sees the features it can run', () {
    List<String> visible(AppPlatform platform) {
      final capabilities = AppCapabilities.forPlatform(platform);
      return [
        for (final feature in LocalFeatureRegistry.all)
          if (feature.supports(capabilities) &&
              feature.tiersFor(platform).isNotEmpty)
            feature.id.name,
      ];
    }

    expect(visible(AppPlatform.linux), [
      'translation',
      'lyrics',
      'transcode',
    ]);
    expect(visible(AppPlatform.android), ['lyrics'],
        reason: 'a phone runs the speech runtime in-app only');
    expect(visible(AppPlatform.windows), isEmpty,
        reason: 'the page hides a block that could never finish');
  });

  test('a lyrics install always brings the second vote', () {
    for (final tier in LocalFeatureRegistry.lyrics.tiersFor(AppPlatform.linux)) {
      final ids = tier.components.map((spec) => spec.id);
      expect(ids, contains(LocalComponentRegistry.sherpaRuntime.id));
      expect(ids, contains(LocalComponentRegistry.sensevoiceModel.id));
    }
  });

  test('the optional engine is only offered where its parts run', () {
    final addon = LocalFeatureRegistry.lyrics.addons.single;

    expect(addon.supports(AppPlatform.linux), isTrue);
    expect(addon.supports(AppPlatform.android), isFalse);
  });

  test('the settings section disappears where nothing can be installed', () {
    bool shown(AppPlatform platform) => settingsSectionSupported(
      SettingsSection.components,
      AppCapabilities.forPlatform(platform),
    );

    expect(shown(AppPlatform.linux), isTrue);
    expect(shown(AppPlatform.android), isTrue);
    expect(shown(AppPlatform.windows), isFalse,
        reason: 'an empty section is worse than no section at all');
  });
}
