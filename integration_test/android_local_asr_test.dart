import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/data/services/impl/media_codec_audio_decoder.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_ffi_transcriber.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_process_transcriber.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_transcript.dart';
import 'package:tune/data/services/smart_lyrics/wav_file.dart';

/// The two Android-only paths of the local AI milestone, on a device:
/// MediaCodec turns a compressed track into 16 kHz mono WAV, and the in-app
/// sherpa-onnx runtime turns that WAV into words (docs/android.md E5).
///
/// Both models must already sit in their component folders. Push them after
/// installing the debug APK and before the run, because the runner replaces
/// the app for the test and removes it when the run ends:
///
/// ```
/// adb install -r build/app/outputs/flutter-apk/app-debug.apk
/// adb push model.int8.onnx /data/local/tmp/sensevoice-model.int8.onnx
/// adb shell run-as cn.iouf.tune mkdir -p files/components/lyrics-sensevoice-model
/// adb shell 'run-as cn.iouf.tune cp /data/local/tmp/sensevoice-model.int8.onnx \
///   files/components/lyrics-sensevoice-model/model.int8.onnx'
/// # same for tokens.txt, and the three whisper files under
/// # files/components/lyrics-whisper-onnx-model
/// flutter test integration_test/android_local_asr_test.dart -d emulator-5554
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MediaCodec decodes a track and the local runtime hears words', (
    tester,
  ) async {
    expect(
      AppCapabilities.current.localAsrBackend,
      LocalAsrBackend.ffi,
      reason: 'this test only runs on the Android build',
    );
    expect(AppCapabilities.current.nativeAudioDecoder, isTrue);

    final support = await getApplicationSupportDirectory();
    final workspace = Directory(p.join(support.path, 'e2e'));
    await workspace.create(recursive: true);

    final asset = await rootBundle.load('assets/test/zh_sample.m4a');
    final audio = File(p.join(workspace.path, 'zh_sample.m4a'));
    await audio.writeAsBytes(
      asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
    );

    final decodeWatch = Stopwatch()..start();
    final wav = await const MediaCodecAudioDecoder().decodeToWav(
      audio,
      folder: workspace,
    );
    decodeWatch.stop();
    expect(wav, isNotNull, reason: 'MediaCodec 应当能解码这条 AAC');
    final header = await WavFile.read(wav!);
    expect(header, isNotNull);
    expect(header!.sampleRate, 16000);
    expect(header.channels, 1);
    expect(header.bitsPerSample, 16);
    expect(header.dataSize, greaterThan(0));
    // ignore: avoid_print
    print(
      'DECODE ${decodeWatch.elapsedMilliseconds} ms '
      '(${header.dataSize} bytes PCM)',
    );

    final modelDir = Directory(
      p.join(support.path, 'components', 'lyrics-sensevoice-model'),
    );
    expect(
      Directory(modelDir.path).existsSync(),
      isTrue,
      reason: '先把 SenseVoice 模型推进 ${modelDir.path}',
    );

    final asrWatch = Stopwatch()..start();
    final transcriber = SherpaFfiTranscriber(
      model: 'sensevoice',
      family: SherpaModelFamily.sensevoice,
      modelDirOf: () async => modelDir,
    );
    addTearDown(transcriber.dispose);
    final answer = await transcriber.listen(wav);
    asrWatch.stop();

    final segments = linesOf(answer.words);
    final text = segments.map((segment) => segment.text).join(' / ');
    // ignore: avoid_print
    print('ASR ${asrWatch.elapsedMilliseconds} ms / ${answer.language}: $text');
    expect(answer.words, isNotEmpty, reason: '本地 ASR 应当听出至少一个词');
    expect(text.trim(), isNotEmpty);
  });

  testWidgets('the whisper ONNX components answer through the same runtime', (
    tester,
  ) async {
    final support = await getApplicationSupportDirectory();
    final workspace = Directory(p.join(support.path, 'e2e'))
      ..createSync(recursive: true);
    final modelDir = Directory(
      p.join(support.path, 'components', 'lyrics-whisper-onnx-model'),
    );
    expect(
      modelDir.existsSync(),
      isTrue,
      reason: '先把 whisper ONNX 三个文件推进 ${modelDir.path}',
    );

    final asset = await rootBundle.load('assets/test/zh_sample.m4a');
    final audio = File(p.join(workspace.path, 'whisper_sample.m4a'));
    await audio.writeAsBytes(
      asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
    );
    final decoded = await const MediaCodecAudioDecoder().decodeToWav(
      audio,
      folder: workspace,
    );
    expect(decoded, isNotNull, reason: 'whisper 用例也要先解码成 WAV');

    final watch = Stopwatch()..start();
    final transcriber = SherpaFfiTranscriber(
      model: 'whisper',
      family: SherpaModelFamily.whisper,
      modelDirOf: () async => modelDir,
    );
    addTearDown(transcriber.dispose);
    final answer = await transcriber.listen(decoded!);
    watch.stop();

    final text = linesOf(answer.words).map((segment) => segment.text).join(' ');
    // ignore: avoid_print
    print('WHISPER ${watch.elapsedMilliseconds} ms / ${answer.language}: $text');
    expect(answer.words, isNotEmpty, reason: 'whisper 应当听出至少一个词');
    expect(text.trim(), isNotEmpty);
  });
}
