import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/l10n/app_localizations.dart';

/// Guards the way the catalogue writes numbers down.
///
/// A reader counts the tracks of a library, the songs of a scan or the
/// results of a search, so the numbers have to be grouped the way the
/// language of the reader groups them.
void main() {
  test('the counts of a catalogue are grouped for the reader', () {
    final english = lookupAppLocalizations(const Locale('en'));
    expect(english.libraryTrackCount(1), '1 track');
    expect(english.libraryTrackCount(1234), '1,234 tracks');
    expect(english.scanSongCount(1234), 'Scanned 1,234 songs');

    final chinese = lookupAppLocalizations(const Locale('zh', 'CN'));
    expect(chinese.libraryTrackCount(1234), '1,234 首');
    expect(chinese.scanSongCount(1234), '已扫描 1,234 首歌曲');
  });

  test('every locale groups the numbers the way it writes them', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final strings = lookupAppLocalizations(locale);
      final count = strings.libraryTrackCount(1234567);

      expect(
        count,
        contains('1'),
        reason: '$locale does not show the number of the tracks',
      );
      expect(
        count,
        isNot(contains('1234567')),
        reason: '$locale writes the number of the tracks without a group',
      );
    }
  });
}
