import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_process_limit.dart';

/// Whatever the machine offers, the recognizer runs with a ceiling: a run
/// that asks the kernel for 128 GiB must die inside its own cgroup.
void main() {
  test('the recognizer always runs behind the binary, never instead of it',
      () async {
    final command = await SherpaProcessLimit.wrap('sherpa-onnx-offline', [
      '--tokens=t',
      'song.wav',
    ]);

    expect(command.arguments, contains('sherpa-onnx-offline'));
    expect(command.arguments.last, 'song.wav');
    expect(command.executable, isNot('sherpa-onnx-offline'));
  });

  test('the scope carries the memory ceiling and no swap', () async {
    final command = await SherpaProcessLimit.wrap('sherpa-onnx-offline', []);

    if (command.executable != 'systemd-run') {
      // No user manager here: the address-space ceiling is the floor.
      expect(command.executable, 'prlimit');
      expect(
        command.arguments.first,
        '--as=${SherpaProcessLimit.addressSpace}',
      );
      return;
    }
    expect(
      command.arguments,
      contains('MemoryMax=${SherpaProcessLimit.memoryMax}'),
    );
    expect(command.arguments, contains('MemorySwapMax=0'));
    expect(command.arguments, contains('-q'),
        reason: 'the scope must not print its own stderr into the reason');
  });
}
