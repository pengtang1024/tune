import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';

/// What the reader came for: one entry installs everything the entry needs.
///
/// The registry still owns the components ([LocalComponentSpec]); a feature
/// only says which of them belong together, so a page never has to know what
/// a runtime is (docs/local-components.md §7).
enum LocalFeatureId { translation, lyrics, transcode }

/// The reader-facing name of a feature. The settings page maps it to text.
enum LocalFeatureLabel { translation, lyrics, transcode }

/// The reader-facing name of a tier.
enum LocalFeatureTierLabel {
  translationLow,
  translationStandard,
  translationQuality,
  lyricsTiny,
  lyricsBase,
  lyricsSmall,
  lyricsLarge,
  lyricsAndroid,
  transcodeBundle,
}

/// The reader-facing name of an optional engine.
enum LocalFeatureAddonLabel { funasrNano }

/// One quality step of a feature: a set of components at a suggested budget.
class LocalFeatureTier {
  final String id;
  final LocalFeatureTierLabel label;

  /// Everything this tier needs, shared components included.
  final List<LocalComponentSpec> components;

  /// Suggested machine, not a hard stop. `0` means no preference.
  final int minRamMb;
  final int minCores;

  /// Room the download needs on top of its own bytes.
  final int diskSlackBytes;

  /// Platforms the tier can run on; `null` means all of them.
  final Set<AppPlatform>? platforms;

  const LocalFeatureTier({
    required this.id,
    required this.label,
    required this.components,
    this.minRamMb = 0,
    this.minCores = 0,
    this.diskSlackBytes = 512 * 1024 * 1024,
    this.platforms,
  });

  bool supports(AppPlatform platform) =>
      platforms == null || platforms!.contains(platform);

  int get downloadBytes =>
      components.fold(0, (sum, component) => sum + component.totalBytes);
}

/// An extra engine the reader may add to a feature, never part of its main
/// install.
class LocalFeatureAddon {
  final LocalFeatureAddonLabel label;
  final List<LocalComponentSpec> components;
  final int minRamMb;
  final int minCores;

  /// Platforms that can run the addon; null means every platform.
  final Set<AppPlatform>? platforms;

  const LocalFeatureAddon({
    required this.label,
    required this.components,
    this.minRamMb = 0,
    this.minCores = 0,
    this.platforms,
  });

  int get downloadBytes =>
      components.fold(0, (sum, component) => sum + component.totalBytes);

  /// An addon is only offered where its own parts can run, even when the
  /// model file itself is not tied to a platform.
  bool supports(AppPlatform platform) =>
      platforms == null || platforms!.contains(platform);
}

/// One feature item of the settings page.
class LocalFeatureSpec {
  final LocalFeatureId id;
  final LocalFeatureLabel label;
  final List<LocalFeatureTier> tiers;
  final List<LocalFeatureAddon> addons;

  /// The tier a healthy machine gets when nothing else decides.
  final String defaultTierId;

  const LocalFeatureSpec({
    required this.id,
    required this.label,
    required this.tiers,
    this.addons = const [],
    this.defaultTierId = '',
  });

  /// Whether this build can run the feature at all. A platform that cannot
  /// execute its binaries does not get an entry it could never finish.
  bool supports(AppCapabilities capabilities) => switch (id) {
    // The desktop pipeline runs an external binary; a phone has none.
    LocalFeatureId.translation => capabilities.externalToolPipeline,
    LocalFeatureId.transcode => capabilities.externalToolPipeline,
    LocalFeatureId.lyrics => capabilities.localAsrBackend != LocalAsrBackend.none,
  };

  List<LocalFeatureTier> tiersFor(AppPlatform platform) => [
    for (final tier in tiers)
      if (tier.supports(platform)) tier,
  ];

  /// Every component the feature can ever own, used for the total footprint
  /// and for the bulk delete.
  Set<LocalComponentSpec> get allComponents => {
    for (final tier in tiers) ...tier.components,
    for (final addon in addons) ...addon.components,
  };
}

/// The three feature items, in the order the settings page shows them.
class LocalFeatureRegistry {
  static final List<LocalFeatureSpec> all = [
    translation,
    lyrics,
    transcode,
  ];

  static LocalFeatureSpec byId(LocalFeatureId id) =>
      all.firstWhere((feature) => feature.id == id);

  static const LocalFeatureSpec translation = LocalFeatureSpec(
    id: LocalFeatureId.translation,
    label: LocalFeatureLabel.translation,
    defaultTierId: 'standard',
    tiers: [
      LocalFeatureTier(
        id: 'low',
        label: LocalFeatureTierLabel.translationLow,
        components: [
          LocalComponentRegistry.translationRuntime,
          LocalComponentRegistry.translationModelLow,
        ],
        minRamMb: 1536,
        minCores: 2,
      ),
      LocalFeatureTier(
        id: 'standard',
        label: LocalFeatureTierLabel.translationStandard,
        components: [
          LocalComponentRegistry.translationRuntime,
          LocalComponentRegistry.translationModel,
        ],
        minRamMb: 2560,
        minCores: 4,
      ),
      LocalFeatureTier(
        id: 'quality',
        label: LocalFeatureTierLabel.translationQuality,
        components: [
          LocalComponentRegistry.translationRuntime,
          LocalComponentRegistry.translationModelQuality,
        ],
        minRamMb: 5120,
        minCores: 6,
        diskSlackBytes: 1024 * 1024 * 1024,
      ),
    ],
  );

  /// The desktop lyrics tiers share the two runtimes and the second vote, so
  /// installing any tier gives the default two-channel pool.
  static final LocalFeatureSpec lyrics = LocalFeatureSpec(
    id: LocalFeatureId.lyrics,
    label: LocalFeatureLabel.lyrics,
    defaultTierId: 'small',
    tiers: [
      _lyricsTier('tiny', LocalFeatureTierLabel.lyricsTiny, 1536, 2),
      _lyricsTier('base', LocalFeatureTierLabel.lyricsBase, 2048, 2),
      _lyricsTier('small', LocalFeatureTierLabel.lyricsSmall, 3072, 4),
      _lyricsTier(
        'large-v3-turbo',
        LocalFeatureTierLabel.lyricsLarge,
        8192,
        8,
        slack: 1024 * 1024 * 1024,
      ),
      const LocalFeatureTier(
        id: 'android',
        label: LocalFeatureTierLabel.lyricsAndroid,
        components: [LocalComponentRegistry.whisperOnnxModelSmall],
        minRamMb: 2048,
        minCores: 2,
        platforms: {AppPlatform.android},
      ),
    ],
    addons: const [
      LocalFeatureAddon(
        label: LocalFeatureAddonLabel.funasrNano,
        components: [LocalComponentRegistry.funasrNanoModel],
        minRamMb: 8192,
        minCores: 8,
        platforms: {AppPlatform.linux},
      ),
    ],
  );

  static const LocalFeatureSpec transcode = LocalFeatureSpec(
    id: LocalFeatureId.transcode,
    label: LocalFeatureLabel.transcode,
    defaultTierId: 'ffmpeg',
    tiers: [
      LocalFeatureTier(
        id: 'ffmpeg',
        label: LocalFeatureTierLabel.transcodeBundle,
        components: [LocalComponentRegistry.ffmpeg],
        diskSlackBytes: 128 * 1024 * 1024,
      ),
    ],
  );

  static LocalFeatureTier _lyricsTier(
    String id,
    LocalFeatureTierLabel label,
    int minRamMb,
    int minCores, {
    int slack = 512 * 1024 * 1024,
  }) {
    return LocalFeatureTier(
      id: id,
      label: label,
      components: [
        LocalComponentRegistry.whisperRuntime,
        LocalComponentRegistry.whisperModel(id),
        LocalComponentRegistry.sherpaRuntime,
        LocalComponentRegistry.sensevoiceModel,
      ],
      minRamMb: minRamMb,
      minCores: minCores,
      diskSlackBytes: slack,
      platforms: const {AppPlatform.linux},
    );
  }
}
