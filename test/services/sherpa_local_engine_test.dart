import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_local_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';

import 'wav_fixture.dart';

/// The second ASR family (docs/smart-lyrics.md §6.2, M12): the sherpa
/// binary answers with token-level timestamps, and the engine cuts lines
/// at the silences — a timing method that owes nothing to whisper.
///
/// The encoder sizes a T×T attention map from the whole file, so these tests
/// also hold the two walls that keep a long track from taking the machine
/// down: the audio is cut into pieces, and only a readable 16 kHz mono WAV
/// is fed to the binary at all.
void main() {
  late Directory root;
  late Directory modelDir;
  late File audio;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_sherpa_engine');
    modelDir = Directory('${root.path}/models')..createSync();
    File('${modelDir.path}/tokens.txt').writeAsStringSync('<pad>\t0\n');
    File('${modelDir.path}/model.int8.onnx').writeAsBytesSync([0]);
    audio = writeWavFile(root, 'one.wav');
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

  SherpaLocalEngine engineOf(
    File binary, {
    Duration chunk = const Duration(minutes: 5),
  }) => SherpaLocalEngine(
    model: 'sensevoice',
    binaryOf: () async => binary,
    modelDirOf: () async => modelDir,
    chunk: chunk,
  );

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

  test('a cancelled run does not poison the channel for the next song',
      () async {
    final binary = await installBinary(r'''
sleep 0.3
cat <<'JSON'
{"tokens": ["甲"], "timestamps": [0.5]}
JSON
''');
    final engine = engineOf(binary);
    final input = SmartAudioInput(audio: audio, title: 'One', artist: 'A');

    final first = engine.runTranscription(input);
    engine.requestCancel();
    await expectLater(first, throwsA(isA<SherpaLocalException>()));

    final second = await engine.runTranscription(input);

    expect(second.segments, isNotEmpty,
        reason: 'a cancel stops one run, not the channel');
  });

  test('a WAV that is not 16 kHz mono never reaches the binary', () async {
    final marker = File('${root.path}/started');
    final binary = await installBinary('touch ${marker.path}; exit 0');
    final stereo = writeWavFile(root, 'stereo.wav', channels: 2);

    await expectLater(
      engineOf(binary).runTranscription(
        SmartAudioInput(audio: stereo, title: 'One', artist: 'Artist'),
      ),
      throwsA(isA<SherpaLocalException>()),
    );
    expect(marker.existsSync(), isFalse,
        reason: 'the binary is what would size its buffers from the header');
  });

  test('a header promising more audio than the file holds fails soft',
      () async {
    final marker = File('${root.path}/started');
    final binary = await installBinary('touch ${marker.path}; exit 0');
    final broken = writeWavFile(
      root,
      'broken.wav',
      frames: 16000,
      // 128 GiB of samples promised by a 32 KB file.
      claimedDataSize: 0x7FFFFFFF,
    );

    await expectLater(
      engineOf(binary).runTranscription(
        SmartAudioInput(audio: broken, title: 'One', artist: 'Artist'),
      ),
      throwsA(isA<SherpaLocalException>()),
    );
    expect(marker.existsSync(), isFalse);
  });

  test('a long track is cut into pieces and every word keeps its place on '
      'one clock', () async {
    final calls = File('${root.path}/calls');
    final binary = await installBinary('''
echo x >> ${calls.path}
cat <<'JSON'
{"tokens": ["甲", "乙"], "timestamps": [0.5, 1.0]}
JSON
''');
    final long = writeWavFile(root, 'long.wav', frames: 5 * 16000);

    final answer = await engineOf(
      binary,
      chunk: const Duration(seconds: 2),
    ).runTranscription(
      SmartAudioInput(audio: long, title: 'One', artist: 'Artist'),
    );

    expect(calls.readAsLinesSync(), hasLength(3),
        reason: 'five seconds at two per piece is three pieces');
    expect(
      answer.segments.map((segment) => segment.start),
      [
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 2500),
        const Duration(milliseconds: 4500),
      ],
      reason: 'the second piece starts where the first one ended',
    );
  });
}

/// A JSON array literal of numbers or strings.
String toksMap(List<dynamic> list) =>
    '[${list.map((value) => value is String ? '"$value"' : value).join(',')}]';
