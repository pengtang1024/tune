import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_reword.dart';

/// The explicit reword of M6 (docs/smart-lyrics.md §7.4): the reader's
/// words replace one line, and nothing else in the sheet moves.
void main() {
  test('the line takes the words and keeps its stamp', () {
    const sheet = '[00:12.50]月亮走我叶走\n[01:12.54]我送阿哥到村口';

    final edited = rewordSheet(sheet, line: 0, text: '月亮走我也走');

    expect(edited, '[00:12.50]月亮走我也走\n[01:12.54]我送阿哥到村口');
  });

  test('a sheet without stamps stays plain words', () {
    const sheet = '第一句\n第二句';

    final edited = rewordSheet(sheet, line: 1, text: '第二句啊');

    expect(edited, '第一句\n第二句啊');
  });

  test('the stamps of the other lines do not move a hair', () {
    const sheet = '[00:01.00]一\n[00:05.25]二\n[00:09.99]三';

    final edited = rewordSheet(sheet, line: 1, text: '贰');

    expect(edited, '[00:01.00]一\n[00:05.25]贰\n[00:09.99]三');
  });

  test('a line that is not there leaves the sheet untouched', () {
    const sheet = '[00:01.00]一';

    expect(rewordSheet(sheet, line: 5, text: '改'), sheet);
    expect(rewordSheet(sheet, line: -1, text: '改'), sheet);
  });
}
