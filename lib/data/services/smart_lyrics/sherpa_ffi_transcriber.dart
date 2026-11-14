import 'dart:io';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:tune/data/services/smart_lyrics/sherpa_ffi_pcm.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_local_exception.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_process_transcriber.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_transcriber.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_transcript.dart';
import 'package:tune/data/services/smart_lyrics/wav_file.dart';

/// Answers one piece through the sherpa-onnx runtime loaded into the app —
/// the Android path (docs/android.md E5).
///
/// A phone cannot execute the downloaded `sherpa-onnx-offline` binary, so the
/// same runtime is linked in and reads the model straight from the component
/// folder. The trade is the process boundary: a native crash takes the app
/// with it, which D1 accepts for Android; the call is bounded by the engine's
/// per-piece timeout and a failure stays a soft failure for that vote.
class SherpaFfiTranscriber implements SherpaTranscriber {
  /// Name the channel votes under (`sensevoice`, `funasr-nano`, `whisper`).
  final String model;

  /// Which model family the folder holds; decides the runtime config.
  final SherpaModelFamily family;

  /// The component folder; `null` means the model is not downloaded.
  final Future<Directory?> Function() modelDirOf;

  SherpaFfiTranscriber({
    required this.model,
    required this.family,
    required this.modelDirOf,
  });

  static var _bindingsReady = false;

  sherpa.OfflineRecognizer? _recognizer;
  var _cancelled = false;

  @override
  void reset() => _cancelled = false;

  @override
  bool get cancelled => _cancelled;

  @override
  void cancel() => _cancelled = true;

  @override
  Future<void> dispose() async {
    _recognizer?.free();
    _recognizer = null;
  }

  @override
  Future<SherpaAnswer> listen(File wav) async {
    if (_cancelled) throw const SherpaLocalException('the run was cancelled');
    final header = await WavFile.read(wav);
    if (header == null) {
      throw SherpaLocalException('${wav.path} is not a readable wav');
    }
    if (!header.isSpeechReady) {
      throw SherpaLocalException(
        'the audio is not 16 kHz mono 16-bit PCM '
        '(${header.sampleRate} Hz, ${header.channels} ch, '
        '${header.bitsPerSample} bit)',
      );
    }
    final recognizer = await _ensureRecognizer();
    final samples = pcm16ToFloat32(await _readSamples(header));
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      recognizer.decode(stream);
      final result = recognizer.getResult(stream);
      if (_cancelled) {
        throw const SherpaLocalException('the run was cancelled');
      }
      // A whisper export without attention outputs answers with tokens but no
      // token times; the text is still a vote, so the words are spread evenly
      // instead of dropped (docs/smart-lyrics.md M13).
      final words = result.timestamps.isEmpty
          ? wordsFromTokensEvenly(result.tokens, header.duration)
          : wordsFromTokens(result.tokens, result.timestamps);
      return SherpaAnswer(
        words,
        result.lang.isEmpty ? null : result.lang,
      );
    } finally {
      stream.free();
    }
  }

  /// The raw PCM of a speech-ready WAV, header skipped.
  Future<Uint8List> _readSamples(WavFile header) async {
    final handle = await header.file.open();
    try {
      await handle.setPosition(header.dataOffset);
      return await handle.read(header.dataSize);
    } finally {
      await handle.close();
    }
  }

  Future<sherpa.OfflineRecognizer> _ensureRecognizer() async {
    final cached = _recognizer;
    if (cached != null) return cached;
    final dir = await modelDirOf();
    if (dir == null) {
      throw SherpaLocalException('the $_modelName model is not downloaded');
    }
    _initBindings();
    final recognizer = sherpa.OfflineRecognizer(_config(dir));
    _recognizer = recognizer;
    return recognizer;
  }

  String get _modelName => switch (family) {
    SherpaModelFamily.sensevoice => 'sensevoice',
    SherpaModelFamily.funAsrNano => 'funasr-nano',
    SherpaModelFamily.whisper => 'whisper',
  };

  sherpa.OfflineRecognizerConfig _config(Directory dir) {
    final root = dir.path;
    final threads = Platform.numberOfProcessors.clamp(1, 4);
    return switch (family) {
      SherpaModelFamily.sensevoice => sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          senseVoice: sherpa.OfflineSenseVoiceModelConfig(
            model: _file(root, 'model.int8.onnx'),
          ),
          tokens: _file(root, 'tokens.txt'),
          numThreads: threads,
          debug: false,
          modelType: 'sensevoice',
        ),
      ),
      SherpaModelFamily.funAsrNano => sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          funasrNano: sherpa.OfflineFunAsrNanoModelConfig(
            encoderAdaptor: _file(root, 'encoder_adaptor.int8.onnx'),
            llm: _file(root, 'llm.int8.onnx'),
            embedding: _file(root, 'embedding.int8.onnx'),
            tokenizer: root,
          ),
          tokens: '',
          numThreads: threads,
          debug: false,
          modelType: 'funasr_nano',
        ),
      ),
      SherpaModelFamily.whisper => sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: _file(root, 'small-encoder.int8.onnx'),
            decoder: _file(root, 'small-decoder.int8.onnx'),
            enableTokenTimestamps: true,
          ),
          tokens: _file(root, 'small-tokens.txt'),
          numThreads: threads,
          debug: false,
          modelType: 'whisper',
        ),
      ),
    };
  }

  /// One model file, or the reason the folder is incomplete.
  static String _file(String root, String name) {
    final file = File('$root/$name');
    if (!file.existsSync()) {
      throw const SherpaLocalException('the model folder is incomplete');
    }
    return file.path;
  }

  /// Loads the native runtime once per isolate; the FFI plugin ships the
  /// library inside the APK.
  static void _initBindings() {
    if (_bindingsReady) return;
    sherpa.initBindings();
    _bindingsReady = true;
  }
}
