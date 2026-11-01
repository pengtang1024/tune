import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tune/data/services/smart_lyrics/sherpa_local_exception.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_process_limit.dart';

/// One run of the recognizer binary: boxed in, cancellable, and answering
/// with the JSON it printed.
///
/// The process mechanics live here so the engine can talk about pieces and
/// words instead. The ceiling comes from [SherpaProcessLimit]: a run that
/// asks for more than it is allowed dies inside its own scope, not in the
/// machine (2026-10-30).
class SherpaRunner {
  Process? _process;
  var _cancelled = false;

  bool get cancelled => _cancelled;

  /// A cancel belongs to the run it stopped, not to the channel: the next
  /// song must be able to use the engine again.
  void reset() => _cancelled = false;

  /// Runs [arguments] through [binary] and returns stdout.
  Future<String> run(File binary, List<String> arguments) async {
    final command = await SherpaProcessLimit.wrap(binary.path, arguments);
    final process = await Process.start(
      command.executable,
      command.arguments,
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
    _process = null;
    if (_cancelled) throw const SherpaLocalException('the run was cancelled');
    if (code != 0) {
      throw SherpaLocalException(
        'sherpa-onnx exited with $code: ${_reason(stderrText)}',
      );
    }
    return stdoutText;
  }

  /// Stops the run. `systemd-run --scope` execs into the binary, so the kill
  /// reaches the recognizer itself rather than a wrapper.
  void cancel() {
    _cancelled = true;
    _process?.kill();
  }

  /// The first line of stderr that says something, without the noise the
  /// wrapper prints on its own.
  static String _reason(String stderrText) => stderrText
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => 'no reason given');

  /// The shared libraries that ride with the binary.
  static String _libraryPathOf(File binary) {
    final root = binary.parent.parent.path;
    final existing = Platform.environment['LD_LIBRARY_PATH'];
    return existing == null || existing.isEmpty
        ? '$root/lib'
        : '$root/lib:$existing';
  }
}
