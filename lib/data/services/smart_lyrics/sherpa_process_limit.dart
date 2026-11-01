import 'dart:io';

/// The ceiling every sherpa run lives under.
///
/// A 42-minute track used to end in one self-attention buffer of 28.9 GB and
/// a 128 GiB request to the kernel, which took the whole desktop down with
/// it. The pieces this engine feeds are at most `chunk` long (~1.8 GB peak
/// measured), so 4 GB is twice what a healthy run needs — and a run that asks
/// for more is killed inside its own scope instead of in the machine.
class SherpaProcessLimit {
  static const String memoryMax = '4G';

  /// The fallback address-space ceiling (6 GiB) when there is no user manager
  /// to put the run in a cgroup.
  static const String addressSpace = '6442450944';

  /// The command that runs [binary], boxed in when the machine can box it.
  ///
  /// `systemd-run --scope` execs into the binary, so cancelling the returned
  /// process still reaches the recognizer rather than a wrapper.
  static Future<({String executable, List<String> arguments})> wrap(
    String binary,
    List<String> arguments,
  ) async {
    if (await _hasSystemdScope()) {
      return (
        executable: 'systemd-run',
        arguments: [
          '--user',
          '--scope',
          // The scope prints "Running as unit" unless told not to, and the
          // engine reads stderr as the reason a run failed.
          '-q',
          '-p',
          'MemoryMax=$memoryMax',
          '-p',
          'MemorySwapMax=0',
          '--',
          binary,
          ...arguments,
        ],
      );
    }
    if (await _hasPrlimit()) {
      return (
        executable: 'prlimit',
        arguments: ['--as=$addressSpace', '--', binary, ...arguments],
      );
    }
    return (executable: binary, arguments: arguments);
  }

  static Future<bool>? _scope;
  static Future<bool>? _prlimit;

  /// Whether a transient *user* scope really works here — the binary being
  /// installed says nothing about a user manager being there to take it.
  static Future<bool> _hasSystemdScope() => _scope ??= _probeSystemdScope();

  static Future<bool> _hasPrlimit() =>
      _prlimit ??= _probe('prlimit', ['--version']);

  static Future<bool> _probeSystemdScope() async {
    try {
      final result = await Process.run('systemd-run', [
        '--user',
        '--scope',
        '-q',
        '-p',
        'MemoryMax=$memoryMax',
        '--',
        'true',
      ]).timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }

  static Future<bool> _probe(String tool, List<String> arguments) async {
    try {
      final result = await Process.run(
        tool,
        arguments,
      ).timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }
}
