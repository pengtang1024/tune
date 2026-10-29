import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';
import 'package:tune/utils/logger.dart';

/// The local sherpa-onnx channel failed (docs/smart-lyrics.md §6.2, M12).
class SherpaLocalException implements Exception {
  final String message;

  const SherpaLocalException(this.message);

  @override
  String toString() => 'SherpaLocalException: $message';
}

/// The second ASR family the confidence story needs (M12): SenseVoice via
/// sherpa-onnx — Apache/MIT licensed, free, offline, and a **different
/// algorithm** from whisper, so the two can cross-prove a line.
///
/// The binary prints one JSON of token-level timestamps to stdout; the
/// engine cuts the text into lines at the silences between tokens — a
/// timing method genuinely independent of whisper's segment model.
class SherpaLocalEngine extends SmartLyricsEngine {
  /// The model name the channel votes under — `sensevoice`.
  final String model;

  /// The `sherpa-onnx-offline` binary; `null` means not installed.
  final Future<File?> Function() binaryOf;

  /// The folder holding `tokens.txt` and the model onnx; `null` means the
  /// model is not downloaded.
  final Future<Directory?> Function() modelDirOf;

  SherpaLocalEngine({
    required this.model,
    required this.binaryOf,
    required this.modelDirOf,
  });

  @override
  String get id => 'local:$model';

  Process? _process;
  var _cancelled = false;

  @override
  Future<TranscriptionResult> runTranscription(
    SmartAudioInput input, {
    void Function(double progress)? onProgress,
  }) async {
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

    _cancelled = false;
    try {
      final process = await Process.start(
        binary.path,
        [
          '--tokens=${tokens.path}',
          '--sense-voice-model=${onnx.path}',
          '--num-threads=${Platform.numberOfProcessors.clamp(1, 4)}',
          input.audio.path,
        ],
        environment: {
          ...Platform.environment,
          'LD_LIBRARY_PATH': _libraryPathOf(binary),
        },
      );
      _process = process;

      // Both pipes listen at once: reading one to the end first would let
      // the other fill and block the child.
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final stdoutText = await stdoutFuture;
      final stderrText = await stderrFuture;
      final code = await process.exitCode;
      if (_cancelled) {
        throw const SherpaLocalException('the run was cancelled');
      }
      if (code != 0) {
        throw SherpaLocalException(
          'sherpa-onnx exited with $code: ${stderrText.split('\n').first}',
        );
      }

      final result = _parse(stdoutText);
      onProgress?.call(1.0);
      return result;
    } catch (error, stackTrace) {
      if (error is SherpaLocalException) {
        Log.error('本地 sherpa 转写失败: $error', stackTrace);
        rethrow;
      }
      Log.error('本地 sherpa 转写失败: $error', stackTrace);
      throw SherpaLocalException('the binary could not run: $error');
    } finally {
      _process = null;
    }
  }

  /// Stops the run; nothing half-written stays because nothing is written.
  @override
  void requestCancel() {
    _cancelled = true;
    _process?.kill();
  }

  /// The shared libraries that ride with the binary.
  static String _libraryPathOf(File binary) {
    final root = binary.parent.parent.path;
    final existing = Platform.environment['LD_LIBRARY_PATH'];
    return existing == null || existing.isEmpty
        ? '$root/lib'
        : '$root/lib:$existing';
  }

  /// The lines of the answer, cut at the silences between tokens.
  ///
  /// A gap of 0.6 seconds closes a line; a line also closes after sixteen
  /// tokens so no monster line swallows the screen. The start of a line
  /// is its first token's time — a measurement that owes nothing to
  /// whisper's segment model.
  TranscriptionResult _parse(String stdoutText) {
    final line = stdoutText
        .split('\n')
        .map((row) => row.trim())
        .firstWhere((row) => row.startsWith('{'), orElse: () => '');
    if (line.isEmpty) {
      throw const SherpaLocalException('the answer has no json');
    }
    final decoded = jsonDecode(line);
    if (decoded is! Map<String, dynamic>) {
      throw const SherpaLocalException('the answer is not an object');
    }
    final tokens = decoded['tokens'];
    final timestamps = decoded['timestamps'];
    final durations = decoded['durations'];
    if (tokens is! List ||
        timestamps is! List ||
        durations is! List ||
        tokens.isEmpty) {
      // No tokens: no words were heard — silence is an answer, not a crash.
      return const TranscriptionResult(segments: []);
    }

    // SenseVoice prints no durations — only starts. The count is tokens
    // against timestamps; a line's end is a token ahead of its last word.
    final count = [tokens.length, timestamps.length].reduce(
      (a, b) => a < b ? a : b,
    );

    final segments = <TranscribedSegment>[];
    final words = <String>[];
    var start = Duration.zero;
    var end = Duration.zero;
    var lastStart = Duration.zero;
    var written = 0;

    void close() {
      if (words.isEmpty) return;
      segments.add(
        TranscribedSegment(
          start: start,
          end: end,
          text: _cleanText(words.join('')),
        ),
      );
      words.clear();
      written = 0;
    }

    for (var i = 0; i < count; i++) {
      final rawToken = '${tokens[i]}';
      if (rawToken.startsWith('<|') || rawToken == '</s>') continue;
      final beginSeconds = _secondsOf(timestamps[i]);
      final begin = Duration(milliseconds: (beginSeconds * 1000).round());

      if (words.isNotEmpty) {
        final gap = begin - lastStart;
        if (gap > const Duration(milliseconds: 600) || written >= 40) {
          close();
        }
      }
      if (words.isEmpty) start = begin;
      words.add(rawToken.replaceAll('▁', ' '));
      written += rawToken.length;
      // The line ends a beat past its last word — no durations to read.
      end = begin + const Duration(milliseconds: 500);
      lastStart = begin;
    }
    close();

    // SenseVoice prints the language under `lang`; some models use
    // `language` — take whichever is there.
    final raw = decoded['language'] ?? decoded['lang'];
    return TranscriptionResult(
      segments: segments,
      language: raw is String ? raw : null,
    );
  }

  static double _secondsOf(Object? value) => value is num ? value.toDouble() : 0;

  static String _cleanText(String text) =>
      text
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'^[.\s]+'), '')
          .trim();
}
