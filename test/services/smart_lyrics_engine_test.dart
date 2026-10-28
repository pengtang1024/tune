import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';

import 'fake_http_adapter.dart';

/// A channel that always answers the same sheet, to pin the contract the
/// real engines inherit (docs/smart-lyrics.md §10, the engine-interface row).
class _FakeEngine extends SmartLyricsEngine {
  _FakeEngine(this.answer);

  final TranscriptionResult answer;

  @override
  String get id => 'fake:test';

  @override
  Future<TranscriptionResult> runTranscription(
    SmartAudioInput input, {
    void Function(double progress)? onProgress,
  }) async => answer;
}

TranscriptionResult _sheet({bool withTimeline = true}) => TranscriptionResult(
  segments: [
    TranscribedSegment(
      start: withTimeline ? const Duration(milliseconds: 1200) : Duration.zero,
      end: withTimeline ? const Duration(milliseconds: 3400) : Duration.zero,
      text: '月亮走我也走',
    ),
  ],
  language: 'zh',
);

void main() {
  final audio = File(
    '${Directory.systemTemp.path}/tune_engine_test/one.mp3',
  );

  test('a fake engine answers a transcription under its own id', () async {
    final engine = _FakeEngine(_sheet());

    final answer = await engine.transcribe(
      SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
    );

    expect(engine.id, 'fake:test');
    expect(answer.segments.single.text, '月亮走我也走');
    expect(answer.language, 'zh');
  });

  test('a sheet with places in time reads as a timeline', () {
    expect(_sheet().hasTimeline, isTrue);
  });

  test('a sheet without places in time is a reference vote only', () {
    expect(_sheet(withTimeline: false).hasTimeline, isFalse);
  });

  test('a disposed engine has no vote left', () {
    final engine = _FakeEngine(_sheet())..dispose();

    expect(
      () => engine.transcribe(
        SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
      ),
      throwsStateError,
    );
  });

  group('the OpenAI-compatible channel', () {
    late FakeHttpAdapter adapter;
    late OpenAiCompatibleEngine engine;
    late File uploaded;

    setUp(() async {
      // The upload reads the audio's bytes, so the file has to be there.
      uploaded = File('${Directory.systemTemp.path}/tune_engine_test/one.mp3')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List<int>.filled(64, 7));
      adapter = FakeHttpAdapter()
        ..body = jsonEncode({
          'text': '月亮走我也走',
          'language': 'zh',
          'segments': [
            {'start': 1.2, 'end': 3.4, 'text': '月亮走我也走'},
            {'start': 4.0, 'end': 6.5, 'text': '我送阿哥到村口'},
          ],
        });
      engine = OpenAiCompatibleEngine(
        model: 'whisper-1',
        client: OpenAiCompatibleClient(
          dio: Dio(BaseOptions(responseType: ResponseType.plain))
            ..httpClientAdapter = adapter,
          baseUrl: 'https://api.test/v1',
          apiKey: 'sk-test',
        ),
      );
    });

    test('the audio goes up as a form, the segments come back timed', () async {
      final sheet = await engine.transcribe(
        SmartAudioInput(audio: uploaded, title: 'One', artist: 'Artist'),
      );

      expect(engine.id, 'cloud:whisper-1');
      expect(adapter.requestedUrls.single, 'https://api.test/v1/audio/transcriptions');
      final form = adapter.requests.single.data as FormData;
      expect(form.fields.map((field) => field.key), contains('model'));
      expect(
        form.fields.map((field) => field.value),
        contains('verbose_json'),
        reason: 'the timeline is the point of the answer',
      );
      expect(form.files, isNotEmpty);
      final authorization = adapter.requests.single.headers['authorization'];
      expect(
        authorization is String ? authorization : (authorization as List).single,
        'Bearer sk-test',
      );

      expect(sheet.segments.first.start, const Duration(milliseconds: 1200));
      expect(sheet.segments.first.end, const Duration(milliseconds: 3400));
      expect(sheet.hasTimeline, isTrue);
      expect(sheet.language, 'zh');
    });

    test('an answer without segments is a reference vote only', () async {
      adapter.body = jsonEncode({'text': '月亮走我也走'});

      final sheet = await engine.transcribe(
        SmartAudioInput(audio: uploaded, title: 'One', artist: 'Artist'),
      );

      expect(sheet.segments, isEmpty);
      expect(sheet.hasTimeline, isFalse);
    });

    test('a broken answer does not become a sheet of thin air', () async {
      adapter.body = 'not json at all';

      final sheet = await engine.transcribe(
        SmartAudioInput(audio: uploaded, title: 'One', artist: 'Artist'),
      );

      expect(sheet.segments, isEmpty);
    });

    test('the text model answers with what it said', () async {
      adapter.body = jsonEncode({
        'choices': [
          {
            'message': {'content': '["一句","两句"]'},
          },
        ],
      });

      final content = await engine.client.complete(
        model: 'gpt-4o-mini',
        prompt: '说两句话',
      );

      expect(content, '["一句","两句"]');
    });
  });
}
