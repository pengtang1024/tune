import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';
import 'package:tune/utils/logger.dart';

/// The local whisper channel failed; the pool votes without it.
class WhisperLocalException implements Exception {
  final String message;

  const WhisperLocalException(this.message);

  @override
  String toString() => 'WhisperLocalException: $message';
}

/// One local whisper.cpp channel (docs/smart-lyrics.md §6.2, M4): the
/// binary runs at a process boundary — a crash inside it never takes the
/// app down — and its JSON is read back only after a clean exit.
///
/// A recent `whisper-cli` decodes flac, mp3, ogg and wav itself, so the
/// audio goes in as it is: no ffmpeg, no intermediate file. An old binary
/// that only reads wav fails the pass, and the channel is skipped — the
/// reader is asked to bring the binary up to date, the pool votes without
/// this channel in the meantime.
class WhisperLocalEngine extends SmartLyricsEngine {
  /// The model name the channel votes under — `base`, `small`, …
  final String model;

  /// The binary: the system one when it is installed, the downloaded one
  /// when it is not; `null` when neither is there.
  final Future<File?> Function() binaryOf;

  /// The model file the words are read with.
  final Future<File?> Function() modelOf;

  /// The folder the run writes its json into, and cleans when it is done.
  ///
  /// The wiring outside the tests names the folder directly; the app
  /// resolves its own folder lazily, so the engine starts without a
  /// file system lookup in its way.
  final Directory? workspace;

  /// The folder the run writes its json into, resolved when [workspace]
  /// is not given.
  final Future<Directory> Function()? workspaceOf;

  WhisperLocalEngine({
    required this.model,
    required this.binaryOf,
    required this.modelOf,
    this.workspace,
    this.workspaceOf,
  });

  @override
  String get id => 'local:$model';

  Process? _process;
  bool _cancelled = false;

  static int _runs = 0;

  @override
  Future<TranscriptionResult> runTranscription(
    SmartAudioInput input, {
    void Function(double progress)? onProgress,
  }) async {
    final binary = await binaryOf();
    if (binary == null) {
      throw const WhisperLocalException('the whisper binary is not installed');
    }
    final modelFile = await modelOf();
    if (modelFile == null) {
      throw const WhisperLocalException('the whisper model is not downloaded');
    }

    final room = await _room();
    // One run, one prefix: three batch workers share the workspace, and a
    // fixed name would let one run read another's answer.
    final prefix = '${room.path}/whisper-out-${_runs++}';
    _cancelled = false;
    try {
      final process = await Process.start(binary.path, [
        '-m',
        modelFile.path,
        '-f',
        input.audio.path,
        // The timeline is the point of the answer, and the progress lines
        // are the only feedback a long pass gives.
        '-oj',
        '-of',
        prefix,
        '-pp',
      ]);
      _process = process;

      unawaited(
        _readProgress(process, onProgress),
      );
      final code = await process.exitCode;
      if (_cancelled) {
        throw const WhisperLocalException('the run was cancelled');
      }
      if (code != 0) {
        throw WhisperLocalException('the binary exited with $code');
      }

      return _answerOf(await _jsonOf(prefix));
    } catch (error, stackTrace) {
      if (error is WhisperLocalException) {
        Log.error('本地转写失败: $error', stackTrace);
        rethrow;
      }
      Log.error('本地转写失败: $error', stackTrace);
      throw WhisperLocalException('the binary could not run: $error');
    } finally {
      _process = null;
      await _cleanup(prefix);
    }
  }

  /// Stops the run between two decode steps; nothing half-written stays.
  @override
  void requestCancel() {
    _cancelled = true;
    _process?.kill();
  }

  /// The folder the run writes its json into.
  Future<Directory> _room() async {
    final given = workspace;
    if (given != null) {
      await given.create(recursive: true);
      return given;
    }
    final resolve = workspaceOf;
    if (resolve == null) {
      throw const WhisperLocalException('the run has no folder to write in');
    }
    final room = await resolve();
    await room.create(recursive: true);
    return room;
  }

  /// The progress lines the binary prints while it works.
  static final RegExp _progressPattern = RegExp(r'progress\s*=\s*([\d.]+)');

  Future<void> _readProgress(Process process, void Function(double)? sink) {
    // Both pipes are drained even when nobody listens: a full pipe would
    // block the child and hang the run on long audio.
    return Future.wait([
      _reportOf(process.stdout, sink),
      _reportOf(process.stderr, sink),
    ]);
  }

  Future<void> _reportOf(
    Stream<List<int>> stream,
    void Function(double)? sink,
  ) async {
    await for (final line in stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (sink == null) continue;
      final match = _progressPattern.firstMatch(line);
      if (match != null) {
        final value = double.tryParse(match.group(1)!);
        if (value != null) sink(value / 100);
      }
    }
  }

  Future<Map<String, dynamic>> _jsonOf(String prefix) async {
    final file = File('$prefix.json');
    if (!await file.exists()) {
      throw const WhisperLocalException('the binary wrote no answer');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is Map<String, dynamic>) return decoded;
    throw const WhisperLocalException('the answer is not an object');
  }

  /// The segments the answer holds; an answer without `transcription` is a
  /// reference vote only, never a lie about the time.
  TranscriptionResult _answerOf(Map<String, dynamic> answer) {
    final rows = answer['transcription'];
    if (rows is! List) return const TranscriptionResult(segments: []);
    return TranscriptionResult(
      segments: [
        for (final row in rows)
          if (row is Map)
            TranscribedSegment(
              start: _msOf(row['offsets'] is Map
                  ? (row['offsets'] as Map)['from']
                  : null),
              end: _msOf(row['offsets'] is Map
                  ? (row['offsets'] as Map)['to']
                  : null),
              text: row['text'] is String
                  ? (row['text'] as String).trim()
                  : '',
            ),
      ],
    );
  }

  static Duration _msOf(Object? value) => Duration(
    milliseconds: value is num ? value.round() : int.tryParse('$value') ?? 0,
  );

  Future<void> _cleanup(String prefix) async {
    for (final suffix in ['.json', '.txt']) {
      final file = File('$prefix$suffix');
      if (await file.exists()) await file.delete();
    }
  }
}
