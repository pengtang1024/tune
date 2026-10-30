import 'dart:io';

import 'package:tune/data/services/smart_lyrics/sherpa_local_exception.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_runner.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_transcript.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';
import 'package:tune/data/services/smart_lyrics/wav_file.dart';
import 'package:tune/data/services/smart_lyrics/wav_splitter.dart';
import 'package:tune/utils/logger.dart';

export 'package:tune/data/services/smart_lyrics/sherpa_local_exception.dart';

/// The binary, the model and the tokens of one channel.
typedef _Target = ({File binary, File tokens, File onnx});

/// The second ASR family the confidence story needs (M12): SenseVoice via
/// sherpa-onnx — Apache/MIT licensed, free, offline, and a **different
/// algorithm** from whisper, so the two can cross-prove a line.
///
/// The binary prints one JSON of token-level timestamps to stdout; the
/// engine cuts the text into lines at the silences between tokens — a
/// timing method genuinely independent of whisper's segment model.
///
/// The encoder is not streaming: it builds a T×T self-attention map from the
/// whole file, so memory grows with the square of the length. A 42-minute
/// track asked for 28.9 GB in one buffer and 128 GiB from the kernel, which
/// took the desktop down (2026-10-30). Two walls keep that from happening
/// again: the audio is cut into [chunk] long pieces, and every piece runs
/// under a 4 GB memory ceiling ([SherpaProcessLimit]).
class SherpaLocalEngine extends SmartLyricsEngine {
  /// The model name the channel votes under — `sensevoice`.
  final String model;

  /// The `sherpa-onnx-offline` binary; `null` means not installed.
  final Future<File?> Function() binaryOf;

  /// The folder holding `tokens.txt` and the model onnx; `null` means the
  /// model is not downloaded.
  final Future<Directory?> Function() modelDirOf;

  /// The longest piece handed to the recognizer at once.
  ///
  /// Measured on the crash input: 60 s → 0.5 GB, 300 s → 1.8 GB, 600 s →
  /// 5.3 GB, 2549 s → 47 GB. Five minutes sits well inside the ceiling.
  final Duration chunk;

  /// A track longer than this is not a song; a header claiming it is a broken
  /// file. Both soft-fail the channel.
  final Duration longestTrack;

  SherpaLocalEngine({
    required this.model,
    required this.binaryOf,
    required this.modelDirOf,
    this.chunk = const Duration(minutes: 5),
    this.longestTrack = const Duration(hours: 6),
  });

  @override
  String get id => 'local:$model';

  final SherpaRunner _runner = SherpaRunner();

  @override
  Future<TranscriptionResult> runTranscription(
    SmartAudioInput input, {
    void Function(double progress)? onProgress,
  }) async {
    final target = await _target();
    final wav = await _readableAudio(input.audio);

    final folder = await Directory.systemTemp.createTemp('tune_sherpa_parts');
    try {
      return await _transcribe(
        wav: wav,
        folder: folder,
        target: target,
        onProgress: onProgress,
      );
    } catch (error, stackTrace) {
      Log.error('本地 sherpa 转写失败: $error', stackTrace);
      if (error is SherpaLocalException) rethrow;
      throw SherpaLocalException('the binary could not run: $error');
    } finally {
      await _discard(folder);
    }
  }

  /// The channel's files, or the reason there is no channel to run.
  Future<_Target> _target() async {
    final binary = await binaryOf();
    if (binary == null) {
      throw const SherpaLocalException('sherpa-onnx is not installed');
    }
    final modelDir = await modelDirOf();
    if (modelDir == null) {
      throw const SherpaLocalException(
        'the sensevoice model is not downloaded',
      );
    }
    final tokens = File('${modelDir.path}/tokens.txt');
    final onnx = File('${modelDir.path}/model.int8.onnx');
    if (!await tokens.exists() || !await onnx.exists()) {
      throw const SherpaLocalException('the model folder is incomplete');
    }
    return (binary: binary, tokens: tokens, onnx: onnx);
  }

  /// The audio, or the reason the binary must not see it.
  ///
  /// The header is read before the binary does: the header is what sizes its
  /// buffers, and a file that promises more samples than it holds turns into
  /// an allocation no machine can serve.
  Future<WavFile> _readableAudio(File audio) async {
    final wav = await WavFile.read(audio);
    if (wav == null) {
      throw SherpaLocalException('${audio.path} is not a readable wav');
    }
    if (!wav.isSpeechReady) {
      throw SherpaLocalException(
        'the audio is not 16 kHz mono 16-bit PCM '
        '(${wav.sampleRate} Hz, ${wav.channels} ch, ${wav.bitsPerSample} bit)',
      );
    }
    if (wav.duration > longestTrack) {
      throw SherpaLocalException(
        'the audio claims ${wav.duration.inHours} h — a broken header, '
        'not a track',
      );
    }
    return wav;
  }

  /// Runs the pieces one after another and joins their words on one clock.
  Future<TranscriptionResult> _transcribe({
    required WavFile wav,
    required Directory folder,
    required _Target target,
    required void Function(double progress)? onProgress,
  }) async {
    final total = wav.partCount(chunk);
    final words = <SherpaWord>[];
    String? language;
    var done = 0;
    await for (final part in wav.parts(folder: folder, chunk: chunk)) {
      if (_cancelled) throw const SherpaLocalException('the run was cancelled');
      final answer = decodeSherpaAnswer(await _run(target, part.file));
      if (answer == null) {
        throw const SherpaLocalException('the answer has no json');
      }
      language ??= answer.language;
      words.addAll(answer.words.map((word) => word.shifted(part.offset)));
      await part.file.delete();
      onProgress?.call(++done / total);
    }
    return TranscriptionResult(segments: linesOf(words), language: language);
  }

  /// One piece through the binary, inside its memory ceiling.
  Future<String> _run(_Target target, File audio) => _runner.run(target.binary, [
    '--tokens=${target.tokens.path}',
    '--sense-voice-model=${target.onnx.path}',
    '--num-threads=${Platform.numberOfProcessors.clamp(1, 4)}',
    audio.path,
  ]);

  /// Stops the run; nothing half-written stays because nothing is written.
  @override
  void requestCancel() => _runner.cancel();

  /// Whether the run was cancelled between two pieces.
  bool get _cancelled => _runner.cancelled;

  static Future<void> _discard(Directory folder) async {
    try {
      if (await folder.exists()) await folder.delete(recursive: true);
    } on FileSystemException catch (error) {
      Log.error('临时分片清理失败: $error');
    }
  }
}
