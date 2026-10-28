import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_text.dart';

import 'fake_http_adapter.dart';

/// The text side of the pipeline (docs/smart-lyrics.md §6.4): the
/// correction of a machine draft and the rebuild from what the model knows.
/// Both demand an equal number of lines — a draft that grows or shrinks is
/// a failure, never a guess.
SmartTextAssist _assist(FakeHttpAdapter adapter) => SmartTextAssist(
  client: OpenAiCompatibleClient(
    dio: Dio(BaseOptions(responseType: ResponseType.plain))
      ..httpClientAdapter = adapter,
    baseUrl: 'https://api.test/v1',
    apiKey: 'sk-test',
  ),
  model: 'gpt-4o-mini',
);

String _contentOf(String content) => jsonEncode({
  'choices': [
    {
      'message': {'content': content},
    },
  ],
});

void main() {
  test('the correction answers line for line', () async {
    final adapter = FakeHttpAdapter()
      ..body = _contentOf('["月亮走我也走","我送阿哥到村口"]');

    final corrected = await _assist(adapter).correctLines(
      title: '月亮走',
      artist: '歌手',
      lines: const ['月亮走我叶走', '我送阿哥到村口'],
    );

    expect(corrected, ['月亮走我也走', '我送阿哥到村口']);
    final asked = adapter.requests.single.data.toString();
    expect(asked.contains('月亮走'), isTrue, reason: 'the prompt knows the song');
    expect(asked.contains('我叶走'), isTrue, reason: 'the draft travels with it');
  });

  test('a fenced answer is unwrapped before it is read', () async {
    final adapter = FakeHttpAdapter()
      ..body = _contentOf('```json\n["一句"]\n```');

    final corrected = await _assist(adapter).correctLines(
      title: 'T',
      artist: 'A',
      lines: const ['一局'],
    );

    expect(corrected, ['一句']);
  });

  test('a draft that changes the line count is a failure', () async {
    final adapter = FakeHttpAdapter()..body = _contentOf('["一句","两句","三句"]');

    expect(
      () => _assist(adapter).correctLines(
        title: 'T',
        artist: 'A',
        lines: const ['一句'],
      ),
      throwsA(isA<SmartLyricsTextException>()),
      reason: 'a corrected sheet that no longer fits the timeline is '
          'useless — the times would be lies',
    );
  });

  test('an answer that is not a list of lines is a failure', () async {
    final adapter = FakeHttpAdapter()..body = _contentOf('这首歌我唱不了');

    expect(
      () => _assist(adapter).correctLines(title: 'T', artist: 'A', lines: const ['一句']),
      throwsA(isA<SmartLyricsTextException>()),
    );
  });

  test('the knowledge vote comes back as plain lines', () async {
    final adapter = FakeHttpAdapter()
      ..body = _contentOf('["月亮走我也走","我送阿哥到村口"]');

    final lines = await _assist(adapter).rebuildLyrics(
      title: '月亮走',
      artist: '歌手',
    );

    expect(lines, ['月亮走我也走', '我送阿哥到村口']);
  });

  test('a knowledge answer that is not lines is dropped', () async {
    final adapter = FakeHttpAdapter()..body = _contentOf('我不知道这首歌');

    expect(
      () => _assist(adapter).rebuildLyrics(title: 'T', artist: 'A'),
      throwsA(isA<SmartLyricsTextException>()),
    );
  });
}
