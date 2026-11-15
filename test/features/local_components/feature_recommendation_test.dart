import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/data/services/system/machine_profile.dart';
import 'package:tune/features/local_components/application/feature_recommendation.dart';

/// The tier a machine should start with (docs/local-components.md §7.6). The
/// thresholds are the contract: an unknown value never filters a tier out and
/// never turns into a made-up number on screen.
void main() {
  const strong = MachineProfile(
    availableMemoryMb: 16384,
    freeDiskBytes: 100 * 1024 * 1024 * 1024,
    cores: 16,
  );

  FeatureRecommendation pick(
    LocalFeatureSpec feature, {
    required MachineProfile profile,
    String languageCode = 'zh',
    Set<String> systemAvailable = const {},
  }) => recommendFeature(
    feature: feature,
    profile: profile,
    platform: AppPlatform.linux,
    languageCode: languageCode,
    systemAvailable: systemAvailable,
  );

  test('a big machine in Chinese or English lands on the middle tier', () {
    final result = pick(LocalFeatureRegistry.translation, profile: strong);

    expect(result.tier.id, 'standard');
    expect(result.certain, isTrue);
  });

  test('a big machine reading another language gets the big translation '
      'model', () {
    final result = pick(
      LocalFeatureRegistry.translation,
      profile: strong,
      languageCode: 'fr',
    );

    expect(result.tier.id, 'quality');
  });

  test('a big machine gets the largest lyrics tier', () {
    final result = pick(LocalFeatureRegistry.lyrics, profile: strong);

    expect(result.tier.id, 'large-v3-turbo');
  });

  test('a weak machine falls back to the first tier and says the resources '
      'are short', () {
    final result = pick(
      LocalFeatureRegistry.translation,
      profile: const MachineProfile(
        availableMemoryMb: 1024,
        freeDiskBytes: 100 * 1024 * 1024 * 1024,
        cores: 2,
      ),
    );

    expect(result.tier.id, 'low');
    expect(result.resourceShort, isTrue);
    expect(result.diskShort, isFalse);
  });

  test('a full disk picks the smallest tier that fits and flags the disk', () {
    final result = pick(
      LocalFeatureRegistry.translation,
      profile: const MachineProfile(
        availableMemoryMb: 16384,
        freeDiskBytes: 0,
        cores: 16,
      ),
    );

    expect(result.tier.id, 'low');
    expect(result.diskShort, isTrue);
    expect(result.certain, isTrue);
  });

  test('a machine with unknown values picks the default and stays uncertain', () {
    final result = pick(
      LocalFeatureRegistry.translation,
      profile: const MachineProfile(cores: 4),
    );

    expect(result.tier.id, 'standard',
        reason: 'nothing measured is not a reason to drop to the small model');
    expect(result.certain, isFalse,
        reason: 'the page then says "fits most computers", not a measured fact');
  });

  test('a tier whose parts are all on the system is reported as such', () {
    final tier = LocalFeatureRegistry.translation.tiers.first;
    final result = pick(
      LocalFeatureRegistry.translation,
      profile: const MachineProfile(
        availableMemoryMb: 1024,
        freeDiskBytes: 0,
        cores: 2,
      ),
      systemAvailable: {for (final spec in tier.components) spec.id},
    );

    expect(result.tier.id, tier.id);
    expect(result.useSystem, isTrue);
  });
}
