import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_local_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';

/// The second ASR family (docs/smart-lyrics.md §6.2, M12): the sherpa
/// binary answers with token-level timestamps, and the engine cuts lines
/// at the silences — a timing method that owes nothing to whisper.
void main() {
  late Directory root;
  late Directory modelDir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_sherpa_engine');
    modelDir = Directory('${root.path}/models')..createSync();
    File('${modelDir.path}/tokens.txt').writeAsStringSync('<pad>\t0\n');
    File('${modelDir.path}/model.int8.onnx').writeAsBytesSync([0]);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// A stand-in binary printing the JSON shape the real one prints.
  Future<File> installBinary(String body) async {
    final file = File('${root.path}/fake-sherpa.sh');
    await file.writeAsString('#!/usr/bin/env bash\n$body');
    await Process.run('chmod', ['+x', file.path]);
    return file;
  }

  SherpaLocalEngine engineOf(File binary) => SherpaLocalEngine(
    model: 'sensevoice',
    binaryOf: () async => binary,
    modelDirOf: () async => modelDir,
  );

  final audio = File('/no-such-audio.wav');

  test('a silence gap closes a line and the line takes the first word\'s '
      'time', () async {
    final binary = await installBinary(r'''
cat <<'JSON'
{"lang": "<|zh|>", "text": "tokens", "tokens": ["<|zh|>", "月亮", "走", "我也", "走", "我送", "阿哥", "到", "村口"], "timestamps": [0.0, 1.0, 1.3, 1.6, 1.9, 4.0, 4.3, 4.6, 4.9], "durations": [0.0, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.5]}
JSON
''');

    final answer = await engineOf(binary).runTranscription(
      SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
    );

    expect(answer.segments, hasLength(2),
        reason: 'the 2.1s silence between 走 and 我送 cuts the line');
    expect(answer.segments.first.start, const Duration(seconds: 1),
        reason: 'the line starts where its first word is sung');
    expect(answer.segments.first.text, '月亮走我也走');
    expect(answer.segments.last.text, '我送阿哥到村口');
    expect(answer.language, '<|zh|>');
  });

  test('sixteen tokens cut a line even without a silence', () async {
    final toks = List.generate(20, (i) => '词$i');
    final stamps = List.generate(20, (i) => i * 0.1);
    final durs = List.generate(20, (_) => 0.1);
    final binary = await installBinary(
      'cat <<\'JSON\'\n'
      '{"tokens": ${toksMap(toks)}, "timestamps": ${toksMap(stamps)}, '
      '"durations": ${toksMap(durs)}}\nJSON\n',
    );

    final answer = await engineOf(binary).runTranscription(
      SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
    );

    expect(answer.segments.length, greaterThanOrEqualTo(2),
        reason: 'the character budget cuts the stream into lines');
  });

  test('an empty answer is silence, not a crash', () async {
    final binary = await installBinary(
      'cat <<\'JSON\'\n'
      '{"tokens": [], "timestamps": [], "durations": []}\nJSON\n',
    );

    final answer = await engineOf(binary).runTranscription(
      SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
    );

    expect(answer.segments, isEmpty);
  });

  test('a failing binary is a failed channel, not a crash', () async {
    final binary = await installBinary('echo boom >&2; exit 3');

    await expectLater(
      engineOf(binary).runTranscription(
        SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
      ),
      throwsA(isA<SherpaLocalException>()),
    );
  });

  test('a missing binary fails before any process starts', () async {
    final engine = SherpaLocalEngine(
      model: 'sensevoice',
      binaryOf: () async => null,
      modelDirOf: () async => modelDir,
    );

    expect(
      engine.runTranscription(
        SmartAudioInput(audio: audio, title: 'One', artist: 'Artist'),
      ),
      throwsA(isA<SherpaLocalException>()),
    );
  });
}

/// A JSON array literal of numbers or strings.
String toksMap(List<dynamic> list) =>
    '[${list.map((value) => value is String ? '"$value"' : value).join(',')}]';
