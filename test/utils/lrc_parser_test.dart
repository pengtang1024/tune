import 'package:flutter_test/flutter_test.dart';
import 'package:tune/ui/player/utils/lrc_parser.dart';

void main() {
  group('LrcParser', () {
    test('parses simple LRC with single timestamp', () {
      const lrc = '''
[00:12.50]First line
[00:25.00]Second line
[00:30.00]Third line
''';
      final parser = LrcParser(lrc);
      expect(parser.lines.length, 3);
      expect(parser.lines[0].timestamp, const Duration(milliseconds: 12500));
      expect(parser.lines[0].text, 'First line');
      expect(parser.lines[2].text, 'Third line');
    });

    test('parses LRC with metadata tags', () {
      const lrc = '''
[ti:Song Title]
[ar:Artist Name]
[al:Album Name]
[00:05.00]Lyric line
''';
      final parser = LrcParser(lrc);
      expect(parser.title, 'Song Title');
      expect(parser.artist, 'Artist Name');
      expect(parser.album, 'Album Name');
      expect(parser.lines.length, 1);
    });

    test('parses LRC with offset', () {
      const lrc = '''
[offset:+1000]
[00:01.00]Delayed line
''';
      final parser = LrcParser(lrc);
      expect(parser.offset, 1000);
      expect(parser.lines[0].timestamp, const Duration(milliseconds: 2000));
    });

    test('parses multi-timestamp lines correctly', () {
      const lrc = '''
[00:10.00][00:20.00]Repeated line
''';
      final parser = LrcParser(lrc);
      expect(parser.lines.length, 2);
      expect(parser.lines[0].timestamp, const Duration(milliseconds: 10000));
      expect(parser.lines[1].timestamp, const Duration(milliseconds: 20000));
    });

    test('finds correct current line index', () {
      const lrc = '''
[00:05.00]A
[00:10.00]B
[00:15.00]C
''';
      final parser = LrcParser(lrc);
      expect(parser.findCurrentLineIndex(const Duration(milliseconds: 7000)), 0);
      expect(parser.findCurrentLineIndex(const Duration(milliseconds: 12000)), 1);
      expect(parser.findCurrentLineIndex(const Duration(milliseconds: 20000)), 2);
      expect(parser.findCurrentLineIndex(Duration.zero), -1);
    });

    test('empty content returns no lines', () {
      final parser = LrcParser('');
      expect(parser.lines, isEmpty);
    });

    test('lines sorted by timestamp', () {
      const lrc = '''
[00:20.00]C
[00:05.00]A
[00:10.00]B
''';
      final parser = LrcParser(lrc);
      expect(parser.lines[0].text, 'A');
      expect(parser.lines[1].text, 'B');
      expect(parser.lines[2].text, 'C');
    });
  });
}
