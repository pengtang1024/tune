import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/data/services/system/machine_profile.dart';

/// The tier this machine should start with, and why.
class FeatureRecommendation {
  final LocalFeatureTier tier;

  /// Memory and disk were both measured, so the claim is about this machine.
  /// When false the page says "fits most computers" instead.
  final bool certain;

  /// The chosen tier does not fit the free disk.
  final bool diskShort;

  /// No tier fits the measured memory and cores.
  final bool resourceShort;

  /// Every component of the tier is already on the system.
  final bool useSystem;

  const FeatureRecommendation({
    required this.tier,
    this.certain = false,
    this.diskShort = false,
    this.resourceShort = false,
    this.useSystem = false,
  });
}

/// Picks the tier for one feature from what the machine reports.
///
/// The rules and their thresholds live in docs/local-components.md §7.6. A
/// value the probe could not read never filters a tier out and never turns
/// into a number on screen.
FeatureRecommendation recommendFeature({
  required LocalFeatureSpec feature,
  required MachineProfile profile,
  required AppPlatform platform,
  required String languageCode,
  Set<String> systemAvailable = const {},
}) {
  final tiers = feature.tiersFor(platform);
  assert(tiers.isNotEmpty, 'recommendFeature needs a supported platform');

  final memory = profile.availableMemoryMb;
  final disk = profile.freeDiskBytes;

  bool fits(LocalFeatureTier tier) =>
      (memory == null || memory >= tier.minRamMb) &&
      profile.cores >= tier.minCores;

  bool diskFits(LocalFeatureTier tier) =>
      disk == null || disk >= tier.downloadBytes + tier.diskSlackBytes;

  final goal = _goalIndex(feature, tiers, profile, languageCode);
  final fitting = [
    for (var index = 0; index < tiers.length; index++)
      if (fits(tiers[index])) index,
  ];
  final withDisk = [
    for (final index in fitting)
      if (diskFits(tiers[index])) index,
  ];

  final chosen = withDisk.isNotEmpty
      ? _closest(withDisk, goal)
      : fitting.isNotEmpty
      ? fitting.first
      : 0;

  final tier = tiers[chosen];
  final usesSystem =
      tier.components.isNotEmpty &&
      tier.components.every((spec) => systemAvailable.contains(spec.id));

  return FeatureRecommendation(
    tier: tier,
    certain: memory != null && disk != null,
    diskShort: !diskFits(tier),
    resourceShort: fitting.isEmpty,
    useSystem: usesSystem,
  );
}

/// Which tier a machine of this class should get.
int _goalIndex(
  LocalFeatureSpec feature,
  List<LocalFeatureTier> tiers,
  MachineProfile profile,
  String languageCode,
) {
  final middle = _indexOfDefault(feature, tiers);
  final memory = profile.availableMemoryMb;

  final weak = profile.cores <= 2 || (memory != null && memory < 3072);
  if (weak) return 0;

  final strong = profile.cores >= 8 && memory != null && memory >= 8192;
  if (!strong) return middle;

  // Qwen handles Chinese and English well at the middle tier; the big model
  // is worth its speed only for other target languages.
  if (feature.id == LocalFeatureId.translation) {
    final zhOrEn =
        languageCode.startsWith('zh') || languageCode.startsWith('en');
    if (zhOrEn) return middle;
  }
  return tiers.length - 1;
}

int _indexOfDefault(LocalFeatureSpec feature, List<LocalFeatureTier> tiers) {
  for (var index = 0; index < tiers.length; index++) {
    if (tiers[index].id == feature.defaultTierId) return index;
  }
  return tiers.length ~/ 2;
}

int _closest(List<int> candidates, int goal) {
  var best = candidates.first;
  for (final candidate in candidates) {
    if ((candidate - goal).abs() < (best - goal).abs()) best = candidate;
  }
  return best;
}
