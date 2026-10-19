import 'package:flutter/widgets.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The name of a language in the language itself.
///
/// The settings page lists the languages the way their speakers call them,
/// so a reader finds their own language at a glance. The names never change
/// with the locale of the interface, a language is always written in itself.
const Map<String, String> _endonyms = {
  'de': 'Deutsch',
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'ja': '日本語',
  'ko': '한국어',
  'ru': 'Русский',
  'zh': '简体中文',
  'zh_CN': '简体中文',
  'zh_TW': '繁體中文',
};

/// The locales the settings page offers.
///
/// The list follows the catalogue of the app, so a new language reaches the
/// settings page without touching this file. The generic language of a
/// catalogue is only offered when no regional variant of it exists, so the
/// list never names the same language twice.
List<Locale> offerableLocales() {
  final locales = AppLocalizations.supportedLocales;
  final regional = <String>{
    for (final locale in locales)
      if (locale.countryCode != null) locale.languageCode,
  };

  return locales
      .where(
        (locale) =>
            locale.countryCode != null ||
            !regional.contains(locale.languageCode),
      )
      .toList(growable: false);
}

/// The name of a locale in the language of that locale.
String localeEndonym(Locale locale) {
  final key = locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';
  return _endonyms[key] ?? locale.toLanguageTag();
}
