import 'package:tune/domain/models/translation_provider.dart';
import 'package:tune/l10n/app_localizations.dart';

/// What the reader sees as the name of a service.
///
/// The catalog names the vendors in their own words, which is right for a
/// brand such as OpenAI or DeepSeek. The two entries that are not brands get
/// the catalogue's translation instead of an English label on a Chinese page.
String translationVendorName(
  AppLocalizations strings,
  TranslationProvider provider,
) {
  return switch (provider.kind) {
    TranslationProviderKind.custom => strings.settingsLocalizationProviderCustom,
    TranslationProviderKind.local => strings.settingsLocalizationProviderLocal,
    _ => provider.name,
  };
}
