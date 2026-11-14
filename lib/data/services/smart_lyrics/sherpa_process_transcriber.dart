import 'dart:io';

import 'package:tune/data/services/smart_lyrics/sherpa_local_exception.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_runner.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_transcriber.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_transcript.dart';

/// The model family the shared `sherpa-onnx-offline` binary recognizes.
enum SherpaModelFamily { sensevoice, funAsrNano, whisper }

/// Answers one piece by starting `sherpa-onnx-offline` — the desktop path.
///
/// The binary prints one JSON of token-level timestamps to stdout; the
/// engine cuts the text into lines at the silences between tokens — a timing
/// method genuinely independent of whisper's segment model.
///
/// A run stays boxed in by [SherpaProcessLimit] (see [SherpaRunner]): the
/// encoder builds a T×T attention map, so a long piece without a ceiling has
/// taken a desktop down (2026-10-30).
class SherpaProcessTranscriber implements SherpaTranscriber {
  /// The model folder's family; decides which flags the binary gets.
  final SherpaModelFamily family;

  /// The `sherpa-onnx-offline` binary; `null` means not installed.
  final Future<File?> Function() binaryOf;

  /// The folder holding the model; `null` means it is not downloaded.
  final Future<Directory?> Function() modelDirOf;

  SherpaProcessTranscriber({
    required this.family,
    required this.binaryOf,
    required this.modelDirOf,
  });

  final SherpaRunner _runner = SherpaRunner();

  @override
  void reset() => _runner.reset();

  @override
  bool get cancelled => _runner.cancelled;

  @override
  void cancel() => _runner.cancel();

  @override
  Future<void> dispose() async {}

  @override
  Future<SherpaAnswer> listen(File wav) async {
    final target = await _target();
    final answer = decodeSherpaAnswer(await _run(target, wav));
    if (answer == null) {
      throw const SherpaLocalException('the answer has no json');
    }
    return answer;
  }

  /// The channel's binary and model flags, or the reason there is no
  /// channel to run.
  Future<({File binary, List<String> args})> _target() async {
    final binary = await binaryOf();
    if (binary == null) {
      throw const SherpaLocalException('sherpa-onnx is not installed');
    }
    final modelDir = await modelDirOf();
    if (modelDir == null) {
      throw SherpaLocalException('the $_modelName model is not downloaded');
    }
    final args = switch (family) {
      SherpaModelFamily.sensevoice => await _senseVoiceArgs(modelDir),
      SherpaModelFamily.funAsrNano => await _funAsrNanoArgs(modelDir),
      SherpaModelFamily.whisper => throw const SherpaLocalException(
        'whisper is not a process model',
      ),
    };
    return (binary: binary, args: args);
  }

  String get _modelName => switch (family) {
    SherpaModelFamily.sensevoice => 'sensevoice',
    SherpaModelFamily.funAsrNano => 'funasr-nano',
    SherpaModelFamily.whisper => 'whisper',
  };

  Future<List<String>> _senseVoiceArgs(Directory modelDir) async {
    final tokens = File('${modelDir.path}/tokens.txt');
    final onnx = File('${modelDir.path}/model.int8.onnx');
    if (!await tokens.exists() || !await onnx.exists()) {
      throw const SherpaLocalException('the model folder is incomplete');
    }
    return [
      '--tokens=${tokens.path}',
      '--sense-voice-model=${onnx.path}',
    ];
  }

  Future<List<String>> _funAsrNanoArgs(Directory modelDir) async {
    final root = modelDir.path;
    final encoder = File('$root/encoder_adaptor.int8.onnx');
    final llm = File('$root/llm.int8.onnx');
    final embedding = File('$root/embedding.int8.onnx');
    // The tokenizer flag names a folder; the binary reads these three out of
    // it and ignores the model files that sit beside them.
    for (final name in const ['vocab.json', 'merges.txt', 'tokenizer.json']) {
      if (!await File('$root/$name').exists()) {
        throw const SherpaLocalException('the model folder is incomplete');
      }
    }
    if (!await encoder.exists() ||
        !await llm.exists() ||
        !await embedding.exists()) {
      throw const SherpaLocalException('the model folder is incomplete');
    }
    return [
      '--funasr-nano-encoder-adaptor=${encoder.path}',
      '--funasr-nano-llm=${llm.path}',
      '--funasr-nano-embedding=${embedding.path}',
      '--funasr-nano-tokenizer=$root',
    ];
  }

  /// One piece through the binary, inside its memory ceiling.
  Future<String> _run(({File binary, List<String> args}) target, File audio) =>
      _runner.run(target.binary, [
        ...target.args,
        '--num-threads=${Platform.numberOfProcessors.clamp(1, 4)}',
        audio.path,
      ]);
}
