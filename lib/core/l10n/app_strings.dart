import 'package:flutter/widgets.dart';
import 'package:tune/l10n/app_localizations.dart';

/// Locale aware strings for code that runs outside of the widget tree.
///
/// Controllers and services cannot ask a [BuildContext] for translations, so
/// they read the strings from here. [LocalizationBridge] keeps the locale in
/// sync with the one the app renders in.
class AppStrings {
  AppStrings._();

  static Locale _locale = const Locale('zh', 'CN');

  /// The locale the app currently renders in.
  static Locale get locale => _locale;

  /// Switches the locale used by [instance].
  static void use(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
  }

  /// The translations of the current locale.
  static AppLocalizations get instance => lookupAppLocalizations(_locale);

  /// The translations of a language, whatever the app renders in.
  ///
  /// A caller that knows the language of its text asks for it here, so the
  /// text never depends on the order the parts of the app run in.
  static AppLocalizations of(Locale locale) => lookupAppLocalizations(locale);
}
