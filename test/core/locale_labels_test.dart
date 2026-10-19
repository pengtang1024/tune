import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/locale_labels.dart';

void main() {
  group('offerable locales', () {
    test('follow the catalogue of the app', () {
      final locales = offerableLocales();

      expect(
        locales.map((locale) => locale.toLanguageTag()),
        containsAll([
          'zh-CN',
          'zh-TW',
          'en',
          'ja',
          'ko',
          'de',
          'fr',
          'es',
          'ru',
        ]),
      );
    });

    test('never name the same language twice', () {
      final names = offerableLocales().map(localeEndonym).toList();

      expect(names.toSet(), hasLength(names.length));
    });

    test('leave out the generic language of a regional variant', () {
      final chinese = offerableLocales()
          .where((locale) => locale.languageCode == 'zh')
          .toList();

      expect(chinese.map((locale) => locale.countryCode), ['CN', 'TW']);
    });
  });

  group('locale endonym', () {
    test('writes a language in its own script', () {
      expect(localeEndonym(const Locale('zh', 'CN')), '简体中文');
      expect(localeEndonym(const Locale('zh', 'TW')), '繁體中文');
      expect(localeEndonym(const Locale('ja')), '日本語');
      expect(localeEndonym(const Locale('ko')), '한국어');
      expect(localeEndonym(const Locale('de')), 'Deutsch');
      expect(localeEndonym(const Locale('fr')), 'Français');
      expect(localeEndonym(const Locale('es')), 'Español');
      expect(localeEndonym(const Locale('ru')), 'Русский');
      expect(localeEndonym(const Locale('en')), 'English');
    });

    test('falls back to the tag of an unknown language', () {
      expect(localeEndonym(const Locale('xx')), 'xx');
    });
  });
}
