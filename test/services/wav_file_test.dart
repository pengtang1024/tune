import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/wav_file.dart';
import 'package:tune/data/services/smart_lyrics/wav_splitter.dart';

import 'wav_fixture.dart';

/// The header is what the ASR binaries size their buffers from, so the reader
/// is where an impossible file is caught — before anything allocates.
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_wav_file');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a 16 kHz mono file is speech ready and knows its length', () async {
    final wav = await WavFile.read(
      writeWavFile(root, 'one.wav', frames: 16000),
    );

    expect(wav, isNotNull);
    expect(wav!.isSpeechReady, isTrue);
    expect(wav.duration, const Duration(seconds: 1));
  });

  test('a 44.1 kHz stereo file is readable but not speech ready', () async {
    final wav = await WavFile.read(
      writeWavFile(
        root,
        'cd.wav',
        sampleRate: 44100,
        channels: 2,
        frames: 44100,
      ),
    );

    expect(wav, isNotNull);
    expect(wav!.isSpeechReady, isFalse, reason: 'the engines read 16 kHz mono');
    expect(wav.duration, const Duration(seconds: 1));
  });

  test('a data chunk longer than the file is a broken file, not a long one',
      () async {
    final wav = await WavFile.read(
      writeWavFile(root, 'broken.wav', claimedDataSize: 0x7FFFFFFF),
    );

    expect(wav, isNull);
  });

  test('a file without the RIFF mark is not a wav', () async {
    final file = File('${root.path}/song.mp3')
      ..writeAsBytesSync(List.filled(64, 0));

    expect(await WavFile.read(file), isNull);
  });

  test('a folder of pieces covers the audio once, with offsets that add up',
      () async {
    final source = writeWavFile(root, 'long.wav', frames: 5 * 16000);
    final wav = await WavFile.read(source);
    final folder = Directory('${root.path}/parts')..createSync();

    final parts = await wav!
        .parts(folder: folder, chunk: const Duration(seconds: 2))
        .toList();

    expect(parts, hasLength(3));
    expect(
      parts.map((part) => part.offset),
      [
        Duration.zero,
        const Duration(seconds: 2),
        const Duration(seconds: 4),
      ],
    );
    expect(
      parts.map((part) => part.length.inMilliseconds).reduce((a, b) => a + b),
      5000,
    );
    for (final part in parts) {
      final piece = await WavFile.read(part.file);
      expect(piece, isNotNull, reason: 'a piece carries a real header');
      expect(piece!.isSpeechReady, isTrue);
    }
  });
}
