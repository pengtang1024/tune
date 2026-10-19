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

    expect(document.lines[0].time.inMilliseconds, 1500);
    expect(document.lines[1].time.inMilliseconds, 2250);
    expect(document.lines[2].time.inMilliseconds, 3125);
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
    expect(document.indexAt(const Duration(seconds: 30)), -1);
  });

  test('finds the line that is sung at a moment', () {
    final document = LyricsDocument.parse('''
[00:10.00]First line
[00:20.00]Second line
[00:30.00]Third line
''');

    expect(document.indexAt(const Duration(seconds: 5)), 0);
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
}
