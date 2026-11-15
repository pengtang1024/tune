import 'dart:io';

import 'package:tune/core/config/platform_constants.dart';

/// What the machine can spare, as far as it can be measured.
///
/// Every field but [cores] may be unknown. The recommendation treats an
/// unknown value as "do not filter on it" and the page shows no number for
/// it (docs/local-components.md §7.6).
class MachineProfile {
  final int? availableMemoryMb;
  final int? freeDiskBytes;
  final int cores;

  const MachineProfile({
    this.availableMemoryMb,
    this.freeDiskBytes,
    this.cores = 1,
  });

  bool get memoryKnown => availableMemoryMb != null;
  bool get diskKnown => freeDiskBytes != null;
}

/// Reads the machine. One implementation per platform, none of them throws:
/// a value it cannot read stays `null`.
abstract class MachineProfileProbe {
  Future<MachineProfile> read();
}

class HostMachineProfileProbe implements MachineProfileProbe {
  /// [diskPath] is where the components will land; the free space of that
  /// file system is the one that matters.
  const HostMachineProfileProbe({this.diskPath});

  final String? diskPath;

  @override
  Future<MachineProfile> read() async {
    final cores = Platform.numberOfProcessors;
    if (!PlatformConstants.isLinux) {
      return MachineProfile(cores: cores);
    }
    return MachineProfile(
      availableMemoryMb: await _availableMemoryMb(),
      freeDiskBytes: await _freeDiskBytes(
        diskPath ?? Platform.environment['HOME'],
      ),
      cores: cores,
    );
  }

  Future<int?> _availableMemoryMb() async {
    try {
      final text = await File('/proc/meminfo').readAsString();
      for (final line in text.split('\n')) {
        if (!line.startsWith('MemAvailable:')) continue;
        final kb = int.tryParse(line.replaceAll(RegExp(r'[^0-9]'), ''));
        if (kb == null) return null;
        return kb ~/ 1024;
      }
    } catch (_) {
      // A kernel without /proc leaves the value unknown; the page then says
      // nothing about memory instead of guessing.
    }
    return null;
  }

  Future<int?> _freeDiskBytes(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final result = await Process.run('df', [
        '-k',
        '--output=avail',
        path,
      ]).timeout(const Duration(seconds: 2));
      if (result.exitCode != 0) return null;
      final lines = (result.stdout as String)
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      final kilobytes = int.tryParse(lines.isEmpty ? '' : lines.last);
      if (kilobytes == null) return null;
      return kilobytes * 1024;
    } catch (_) {
      return null;
    }
  }
}
