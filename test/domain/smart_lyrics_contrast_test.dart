import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_contrast.dart';

/// The contrasts of M7 (docs/smart-lyrics.md §7.5): keyed by the sheet
/// they were made from, so a regenerated sheet lets the old ones go quiet.
void main() {
  test('the machine header names the sheet the contrasts belong to', () {
    const sheet = '[tune:smart]\n[votes:3]\n[date:2026-10-29]\n[00:01.00]一';

    expect(contrastSheetKey(sheet), '2026-10-29');
    expect(contrastSheetKey('[00:01.00]一'), isNull);
  });

  test('the record survives a json round trip', () {
    const contrast = SmartSongContrast(
      sheetDate: '2026-10-29',
      translationLanguage: 'English',
      translation: ['One', 'Two'],
      transliteration: ['yi', 'er'],
    );

    final restored = contrastFromJson(contrastToJson(contrast));

    expect(restored!.sheetDate, '2026-10-29');
    expect(restored.translation, ['One', 'Two']);
    expect(restored.transliteration, ['yi', 'er']);
    expect(restored.isEmpty, isFalse);
  });

  test('one contrast may stand without the other', () {
    const contrast = SmartSongContrast(
      sheetDate: '2026-10-29',
      translation: ['One'],
    );

    final restored = contrastFromJson(contrastToJson(contrast))!;

    expect(restored.translation, ['One']);
    expect(restored.transliteration, isNull);
  });

  test('a file nothing can be read of is no contrast', () {
    expect(contrastFromJson(null), isNull);
    expect(contrastFromJson('   '), isNull);
    expect(contrastFromJson('not json'), isNull);
    expect(contrastFromJson('["a list"]'), isNull);
    expect(contrastFromJson('{"translation": 42}')!.translation, isNull,
        reason: 'a field of the wrong shape falls to nothing, not a crash');
    expect(SmartSongContrast.empty.isEmpty, isTrue);
  });
}
