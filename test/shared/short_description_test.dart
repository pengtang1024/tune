import 'package:flutter_test/flutter_test.dart';
import 'package:tune/shared/utils/short_description.dart';

void main() {
  group('shorten', () {
    test('a short text is kept with its spacing tidied', () {
      expect(shorten('  A note   about the mix.  '), 'A note about the mix.');
    });

    test('a long text is cut at the length asked for', () {
      final text = 'a' * 700;

      final short = shorten(text, length: 600);

      expect(short, hasLength(601));
      expect(short!.endsWith('…'), isTrue);
    });

    test('an empty text is no description at all', () {
      expect(shorten(''), isNull);
      expect(shorten('   '), isNull);
      expect(shorten(null), isNull);
    });

    test('a description written as HTML keeps its words', () {
      expect(
        shortDescription('<p>A note about <b>the</b> song.</p>'),
        'A note about the song.',
      );
    });

    test('a tag taken out leaves no space before a mark of punctuation', () {
      expect(
        shortDescription('<p>A novel about <b>a court case</b>.</p>'),
        'A novel about a court case.',
      );
    });
  });
}
