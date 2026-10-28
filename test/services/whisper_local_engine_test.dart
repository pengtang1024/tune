import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';
import 'package:tune/data/services/smart_lyrics/whisper_local_engine.dart';

/// The local whisper channel (docs/smart-lyrics.md §6.2, M4): a subprocess
/// at a process boundary, its JSON read back only after a clean exit, its
/// run cancellable in flight, nothing half-written left behind.
void main() {
  late Directory workspace;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('tune_whisper_engine');
  });

  tearDown(() async {
    if (await workspace.exists()) await workspace.delete(recursive: true);
  });

  /// The lines every stand-in binary starts with: it reads the arguments
  /// the engine passed, the way the real `whisper-cli` does.
  const preamble = r'''
PREFIX=""
MODEL=""
AUDIO=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -m) MODEL="$2";;
    -f) AUDIO="$2";;
    -of) PREFIX="$2";;
  esac
  shift
done
''';

  /// Writes a shell script that stands in for `whisper-cli`.
  Future<File> installBinary(String body) async {
    final file = File('${workspace.path}/fake-whisper.sh');
    await file.writeAsString('#!/usr/bin/env bash\n$preamble$body');
    await Process.run('chmod', ['+x', file.path]);
    return file;
  }

  final audio = File('/does-not-have-to-exist.mp3');

  WhisperLocalEngine engineOf(File binary) => WhisperLocalEngine(
    model: 'base',
    binaryOf: () async => binary,
    modelOf: () async => File('${workspace.path}/ggml-base.bin'),
    workspace: workspace,
  );

  test('the model file and the audio go in, the json comes back as segments',
      () async {
    final binary = await installBinary(r'''
cat > "$PREFIX.json" <<JSON
{"transcription":[
  {"offsets":{"from":1200,"to":3400},"text":" 月亮走我也走"},
  {"offsets":{"from":4000,"to":6500},"text":" m=$MODEL f=$AUDIO"}
]}
JSON
''');

    final engine = engineOf(binary);
    final answer = await engine.transcribe(
      SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
    );

    expect(engine.id, 'local:base');
    expect(answer.segments, hasLength(2));
    expect(answer.segments.first.start, const Duration(milliseconds: 1200));
    expect(answer.segments.first.end, const Duration(milliseconds: 3400));
    expect(answer.segments.first.text.trim(), '月亮走我也走');
    expect(answer.hasTimeline, isTrue);
    expect(
      answer.segments.last.text,
      contains('ggml-base.bin'),
      reason: 'the model file the engine was given is the one the run used',
    );
    expect(answer.segments.last.text, contains(audio.path));
  });

  test('progress lines travel to the callback', () async {
    final binary = await installBinary(r'''
echo 'whisper_print_progress_callback: progress = 42%'
cat > "$PREFIX.json" <<'JSON'
{"transcription":[{"offsets":{"from":0,"to":100},"text":"x"}]}
JSON
''');

    final percents = <double>[];
    await engineOf(binary).transcribe(
      SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
      onProgress: percents.add,
    );

    expect(percents, isNotEmpty);
    expect(percents.last, closeTo(0.42, 0.001));
  });

  test('a failing binary is a failed channel, not a crash', () async {
    final binary = await installBinary('exit 3');

    await expectLater(
      engineOf(binary).transcribe(
        SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
      ),
      throwsA(isA<WhisperLocalException>()),
    );
  });

  test('a cancelled run stops the process and leaves nothing behind', () async {
    final binary = await installBinary(r'''
sleep 30
cat > "$PREFIX.json" <<'JSON'
{"transcription":[{"offsets":{"from":0,"to":100},"text":"x"}]}
JSON
''');
    final engine = engineOf(binary);

    final run = engine.transcribe(
      SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    engine.requestCancel();

    await expectLater(run, throwsA(isA<WhisperLocalException>()));
    expect(
      workspace
          .listSync()
          .whereType<File>()
          .map((file) => file.path),
      everyElement(contains('fake-whisper.sh')),
      reason: 'the run cleaned its outputs — a half sheet never stays',
    );
  });

  test('a missing binary is a failed channel before any process starts', () {
    final engine = WhisperLocalEngine(
      model: 'base',
      binaryOf: () async => null,
      modelOf: () async => File('${workspace.path}/ggml-base.bin'),
      workspace: workspace,
    );

    expect(
      engine.transcribe(
        SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
      ),
      throwsA(isA<WhisperLocalException>()),
    );
  });

  test('an answer without segments is a reference vote only', () async {
    final binary = await installBinary(r'''
cat > "$PREFIX.json" <<'JSON'
{"transcription":[]}
JSON
''');

    final answer = await engineOf(binary).transcribe(
      SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
    );

    expect(answer.segments, isEmpty);
  });
}
