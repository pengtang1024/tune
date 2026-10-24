import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';

void main() {
  test('reads the time stamps of a lyric sheet', () {
    final document = LyricsDocument.parse('''
[00:12.00]First line
[00:15.30]Second line
''');

    expect(document.isTimed, isTrue);
    expect(document.lines, hasLength(2));
    expect(document.lines.first.time, const Duration(seconds: 12));
    expect(document.lines.first.text, 'First line');
    expect(
      document.lines.last.time,
      const Duration(seconds: 15, milliseconds: 300),
    );
  });

  test('reads the different fraction sizes', () {
    final document = LyricsDocument.parse('''
[00:01.5]Half a second
[00:02.25]A quarter
[00:03.125]A fraction
''');

    expect(document.lines[0].time, const Duration(milliseconds: 1500));
    expect(document.lines[1].time, const Duration(milliseconds: 2250));
    expect(document.lines[2].time, const Duration(milliseconds: 3125));
  });

  test('keeps a line that carries several time stamps', () {
    final document = LyricsDocument.parse('[00:10.00][01:20.00]Chorus');

    expect(document.lines, hasLength(2));
    expect(document.lines.first.time, const Duration(seconds: 10));
    expect(document.lines.last.time, const Duration(seconds: 80));
    expect(document.lines.last.text, 'Chorus');
  });

  test('keeps a sheet without time stamps as plain text', () {
    final document = LyricsDocument.parse('First line\nSecond line');

    expect(document.isTimed, isFalse);
    expect(document.lines, hasLength(2));
    expect(document.lines.first.text, 'First line');
    expect(document.lines.first.time, isNull);
    expect(document.indexAt(const Duration(seconds: 30)), -1);
  });

  test('finds the line that is sung at a moment', () {
    final document = LyricsDocument.parse('''
[00:10.00]First line
[00:20.00]Second line
[00:30.00]Third line
''');

    expect(document.indexAt(const Duration(seconds: 15)), 0);
    expect(document.indexAt(const Duration(seconds: 25)), 1);
    expect(document.indexAt(const Duration(seconds: 35)), 2);
  });

  test('sorts the lines by their time', () {
    final document = LyricsDocument.parse('''
[00:30.00]Third line
[00:10.00]First line
[00:20.00]Second line
''');

    expect(document.lines.map((line) => line.text), [
      'First line',
      'Second line',
      'Third line',
    ]);
  });

  test('does not highlight a line before it is sung', () {
    final document = LyricsDocument.parse('''
[00:10.00]First line
[00:20.00]Second line
''');

    expect(document.indexAt(Duration.zero), -1);
    expect(document.indexAt(const Duration(seconds: 9)), -1);
    expect(document.indexAt(const Duration(seconds: 10)), 0);
  });

  test('keeps the order of the lines that share a time', () {
    final document = LyricsDocument.parse('''
[00:10.00]First line
[00:10.00]Second line
[00:20.00]Third line
''');

    expect(document.lines.map((line) => line.text), [
      'First line',
      'Second line',
      'Third line',
    ]);
  });

  test('does not read the header of the sheet as lyrics', () {
    final document = LyricsDocument.parse('''
[ti:So What]
[ar:Miles Davis]
[al:Kind Of Blue]
[au:Some One]
[by:Another One]
[re:Editor]
[ve:1.0]
[length:09:25]
[00:12.00]First line
''');

    expect(document.lines, hasLength(1));
    expect(document.lines.first.text, 'First line');
  });

  test('moves the sheet by the offset it declares', () {
    final document = LyricsDocument.parse('''
[offset:+500]
[00:12.00]First line
[00:20.00]Second line
''');

    expect(document.lines.first.time, const Duration(seconds: 11, milliseconds: 500));
    expect(document.lines.last.time, const Duration(seconds: 19, milliseconds: 500));
  });

  test('moves the sheet back by a negative offset', () {
    final document = LyricsDocument.parse('''
[offset:-1000]
[00:12.00]First line
''');

    expect(document.lines.first.time, const Duration(seconds: 13));
  });

  test('reads a sheet that starts at zero as a timed sheet', () {
    final document = LyricsDocument.parse('[00:00.00]First line');

    expect(document.isTimed, isTrue);
    expect(document.lines.first.time, Duration.zero);
  });

  test('keeps the lines without a time stamp after the timed ones', () {
    final document = LyricsDocument.parse('''
A line without a time stamp
[00:10.00]First line
[00:20.00]Second line
''');

    expect(document.lines, hasLength(3));
    expect(document.lines[0].text, 'First line');
    expect(document.lines[1].text, 'Second line');
    expect(document.lines[2].text, 'A line without a time stamp');
    expect(document.lines[2].time, isNull);
  });

  test('does not highlight a line that carries no time stamp', () {
    final document = LyricsDocument.parse('''
[00:10.00]First line
A line without a time stamp
''');

    expect(document.indexAt(const Duration(seconds: 30)), 0);
  });

  test('drops the word tags of an enhanced sheet', () {
    final document = LyricsDocument.parse(
      '[00:12.00]Hello <00:12.00>world <00:12.50>',
    );

    expect(document.lines.first.text, 'Hello world');
  });
}
