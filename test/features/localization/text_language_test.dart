import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/localization/domain/text_language.dart';

void main() {
  group('targetLanguageOf', () {
    test('keeps the Chinese variants apart', () {
      expect(targetLanguageOf(const Locale('zh')), 'zh-CN');
      expect(targetLanguageOf(const Locale('zh', 'CN')), 'zh-CN');
      expect(targetLanguageOf(const Locale('zh', 'TW')), 'zh-TW');
      expect(targetLanguageOf(const Locale('zh', 'HK')), 'zh-TW');
      expect(targetLanguageOf(const Locale('zh', 'MO')), 'zh-TW');
    });

    test('passes other languages through', () {
      expect(targetLanguageOf(const Locale('en')), 'en');
      expect(targetLanguageOf(const Locale('ja', 'JP')), 'ja');
    });
  });

  group('needsTranslation', () {
    test('a Chinese title is done in a Chinese interface', () {
      expect(needsTranslation('晴天', 'zh-CN'), isFalse);
      expect(needsTranslation('晴天', 'zh-TW'), isFalse);
    });

    test('a list a reader named in Chinese is not translated', () {
      // A playlist or an album is the reader's own name for a set of tracks;
      // a Chinese name in a Chinese interface is already the words they chose.
      expect(needsTranslation('我的歌单', 'zh-CN'), isFalse);
      expect(needsTranslation('深夜歌单 Vol.2', 'zh-CN'), isFalse);
    });

    test('a Latin title is translated into Chinese', () {
      expect(needsTranslation('Blue in Green', 'zh-CN'), isTrue);
    });

    test('Japanese with kana is not Chinese', () {
      expect(needsTranslation('君の名は', 'zh-CN'), isTrue);
    });

    test('Latin is left alone in an English interface', () {
      expect(needsTranslation('Blue in Green', 'en'), isFalse);
      expect(needsTranslation('Привет', 'en'), isTrue);
    });

    test('numbers and short strings are never sent', () {
      expect(needsTranslation('123', 'zh-CN'), isFalse);
      expect(needsTranslation('A', 'zh-CN'), isFalse);
      expect(needsTranslation('  ', 'zh-CN'), isFalse);
    });

    test('a language without a shortcut translates everything', () {
      expect(needsTranslation('晴天', 'ja'), isTrue);
    });
  });

  test('normalize folds the whitespace and keeps the case', () {
    expect(normalizeTranslatableText('  Blue   in\nGreen  '), 'Blue in Green');
  });
}
