import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_ffi_pcm.dart';

/// The in-app runtime wants float samples and answers with raw tokens. Both
/// translations are pure, so they are tested without loading a model.
void main() {
  test('16-bit PCM becomes float samples in the readable range', () {
    final bytes = Uint8List.fromList([
      0x00, 0x00, // 0
      0xff, 0x7f, // 32767
      0x00, 0x80, // -32768
      0xff, 0xff, // -1
    ]);

    final samples = pcm16ToFloat32(bytes);

    expect(samples, hasLength(4));
    expect(samples[0], 0);
    expect(samples[1], closeTo(1, 1e-4));
    expect(samples[2], closeTo(-1, 1e-6));
    expect(samples[3], closeTo(-1 / 32768, 1e-6));
  });

  test('an odd byte is ignored, not read past the end', () {
    final samples = pcm16ToFloat32(Uint8List.fromList([0x01, 0x00, 0x7f]));

    expect(samples, hasLength(1));
  });

  test('language and event tags never become words', () {
    final words = wordsFromTokens(
      ['<|zh|>', '<|NEUTRAL|>', '<|Speech|>', '月亮', '▁走', '</s>'],
      [0.0, 0.1, 0.2, 1.0, 1.3, 1.6],
    );

    expect(words.map((word) => word.text), ['月亮', ' 走']);
    expect(words.map((word) => word.start), [1.0, 1.3]);
  });

  test('the shorter of tokens and timestamps bounds the words', () {
    final words = wordsFromTokens(['月亮', '走', '我'], [1.0, 1.3]);

    expect(words, hasLength(2));
    expect(words.last.start, 1.3);
  });

  test('a model without token times spreads its words over the audio', () {
    final words = wordsFromTokensEvenly(
      ['<|zh|>', '開', '放', '</s>'],
      const Duration(seconds: 2),
    );

    expect(words.map((word) => word.text), ['開', '放']);
    expect(words.map((word) => word.start), [0, 1]);
  });

  test('nothing but tags gives no words at all', () {
    expect(
      wordsFromTokensEvenly(['<|zh|>', '</s>'], const Duration(seconds: 2)),
      isEmpty,
    );
  });
}
