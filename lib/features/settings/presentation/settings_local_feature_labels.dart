import 'package:flutter/widgets.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_feature.dart';

/// The reader-facing text of the feature list.
///
/// The data layer only carries enums; every string lives in the ARB files
/// (docs/i18n.md).
String featureTitle(BuildContext context, LocalFeatureLabel label) {
  final strings = context.loc;
  return switch (label) {
    LocalFeatureLabel.translation => strings.settingsLocalFeatureTranslation,
    LocalFeatureLabel.lyrics => strings.settingsLocalFeatureLyrics,
    LocalFeatureLabel.transcode => strings.settingsLocalFeatureTranscode,
  };
}

String featureDescription(BuildContext context, LocalFeatureLabel label) {
  final strings = context.loc;
  return switch (label) {
    LocalFeatureLabel.translation =>
      strings.settingsLocalFeatureTranslationDesc,
    LocalFeatureLabel.lyrics => strings.settingsLocalFeatureLyricsDesc,
    LocalFeatureLabel.transcode =>
      strings.settingsLocalFeatureTranscodeDesc,
  };
}

String tierTitle(BuildContext context, LocalFeatureTierLabel label) {
  final strings = context.loc;
  return switch (label) {
    LocalFeatureTierLabel.translationLow => strings.settingsLocalFeatureTierLow,
    LocalFeatureTierLabel.translationStandard =>
      strings.settingsLocalFeatureTierStandard,
    LocalFeatureTierLabel.translationQuality =>
      strings.settingsLocalFeatureTierQuality,
    LocalFeatureTierLabel.lyricsTiny => strings.settingsLocalFeatureTierTiny,
    LocalFeatureTierLabel.lyricsBase => strings.settingsLocalFeatureTierBase,
    LocalFeatureTierLabel.lyricsSmall => strings.settingsLocalFeatureTierSmall,
    LocalFeatureTierLabel.lyricsLarge => strings.settingsLocalFeatureTierLarge,
    LocalFeatureTierLabel.lyricsAndroid =>
      strings.settingsLocalFeatureTierAndroid,
    LocalFeatureTierLabel.transcodeBundle =>
      strings.settingsLocalFeatureTranscode,
  };
}

String tierDescription(BuildContext context, LocalFeatureTierLabel label) {
  final strings = context.loc;
  return switch (label) {
    LocalFeatureTierLabel.translationLow =>
      strings.settingsLocalFeatureTierLowDesc,
    LocalFeatureTierLabel.translationStandard =>
      strings.settingsLocalFeatureTierStandardDesc,
    LocalFeatureTierLabel.translationQuality =>
      strings.settingsLocalFeatureTierQualityDesc,
    LocalFeatureTierLabel.lyricsTiny => strings.settingsLocalFeatureTierTinyDesc,
    LocalFeatureTierLabel.lyricsBase => strings.settingsLocalFeatureTierBaseDesc,
    LocalFeatureTierLabel.lyricsSmall =>
      strings.settingsLocalFeatureTierSmallDesc,
    LocalFeatureTierLabel.lyricsLarge =>
      strings.settingsLocalFeatureTierLargeDesc,
    LocalFeatureTierLabel.lyricsAndroid =>
      strings.settingsLocalFeatureTierAndroidDesc,
    LocalFeatureTierLabel.transcodeBundle =>
      strings.settingsLocalFeatureTranscodeDesc,
  };
}

String addonTitle(BuildContext context, LocalFeatureAddonLabel label) {
  final strings = context.loc;
  return switch (label) {
    LocalFeatureAddonLabel.funasrNano =>
      strings.settingsLocalFeatureAddonFunasr,
  };
}

String addonDescription(BuildContext context, LocalFeatureAddonLabel label) {
  final strings = context.loc;
  return switch (label) {
    LocalFeatureAddonLabel.funasrNano =>
      strings.settingsLocalFeatureAddonFunasrDesc,
  };
}
