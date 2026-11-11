import 'package:flutter/widgets.dart';

/// The language the app translates into, as a BCP-47 tag.
String targetLanguageOf(Locale locale) {
  if (locale.languageCode == 'zh') {
    final country = locale.countryCode;
    if (country == 'TW' || country == 'HK' || country == 'MO') {
      return 'zh-TW';
    }
    return 'zh-CN';
  }
  return locale.languageCode;
}

/// Whether [text] still needs a translation for [targetLanguage].
///
/// The decision is made from the script, not from the `language` field of a
/// track: many sources fill that field with `English` for a Chinese title.
/// Names and numbers are left alone, and a text that already carries the
/// script of the target language is not sent anywhere.
bool needsTranslation(String text, String targetLanguage) {
  final value = normalizeTranslatableText(text);
  if (value.length < 2) return false;
  if (!_letters.hasMatch(value)) return false;

  final target = targetLanguage.toLowerCase();
  final han = _han.hasMatch(value);
  final kana = _kana.hasMatch(value);
  final hangul = _hangul.hasMatch(value);

  if (target.startsWith('zh')) {
    // Japanese titles mix kanji with kana; they are not Chinese.
    if (kana || hangul) return true;
    return !han;
  }
  if (target.startsWith('en')) {
    // Latin text is treated as English. A French or Spanish title is the
    // known miss of this shortcut; the advanced page can revisit it later.
    if (han || kana || hangul) return true;
    return _nonLatin.hasMatch(value);
  }
  return true;
}

/// Trims the text and folds the whitespace; the case is kept so names survive.
String normalizeTranslatableText(String text) =>
    text.trim().replaceAll(_whitespace, ' ');

final RegExp _whitespace = RegExp(r'\s+');
final RegExp _han = RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]');
final RegExp _kana = RegExp(r'[\u3040-\u30FF]');
final RegExp _hangul = RegExp(r'[\u1100-\u11FF\uAC00-\uD7AF]');
final RegExp _nonLatin = RegExp(
  r'[\u0400-\u04FF\u0530-\u058F\u0590-\u05FF\u0600-\u06FF'
  r'\u0900-\u097F\u0E00-\u0E7F]',
);
final RegExp _letters = RegExp(
  r'[A-Za-z\u00C0-\u024F\u0400-\u04FF\u0530-\u058F\u0590-\u05FF'
  r'\u0600-\u06FF\u0900-\u097F\u0E00-\u0E7F'
  r'\u3040-\u30FF\u3400-\u4DBF\u4E00-\u9FFF\uAC00-\uD7AF]',
);
