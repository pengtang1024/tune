import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/library/lyrics_text.dart';

void main() {
  test('reads a file that is written in utf-8', () {
    final bytes = utf8.encode('[00:12.00]第一行');

    expect(decodeLyricsText(bytes), '[00:12.00]第一行');
  });

  test('reads a file that begins with a mark', () {
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('[00:12.00]First line')];

    expect(decodeLyricsText(bytes), '[00:12.00]First line');
  });

  test('reads a file that is written in gbk', () {
    final bytes = gbk.encode('[00:12.00]第一行');

    expect(decodeLyricsText(bytes), '[00:12.00]第一行');
  });

  test('an empty file holds no text', () {
    expect(decodeLyricsText(const []), isNull);
  });
}
