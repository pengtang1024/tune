import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';

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
}
