import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_components.dart';

/// The resolve order is fixed (docs/local-components.md §3): what the machine
/// already has wins, then what an older release wrote, then the download.
void main() {
  late Directory root;
  late Directory systemFolder;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_resolver');
    systemFolder = Directory(path.join(root.path, 'bin'));
    await systemFolder.create(recursive: true);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  final runtime = LocalComponentSpec(
    id: 'test-runtime',
    kind: LocalComponentKind.runtime,
    label: LocalComponentLabel.whisperRuntime,
    files: const [],
    executable: 'whisper-cli',
    systemNames: const ['whisper-cli'],
    legacyDirectories: const ['whisper/bin'],
  );

  final model = LocalComponentSpec(
    id: 'test-model',
    kind: LocalComponentKind.model,
    label: LocalComponentLabel.translationModel,
    files: const [],
    requiredFiles: const ['model.bin'],
    legacyFiles: const ['translation/models/model.bin'],
  );

  LocalComponents componentsWith({required String pathValue}) =>
      LocalComponents(
        supportDirectory: Directory(path.join(root.path, 'support')),
        environment: {'PATH': pathValue, 'HOME': root.path},
      );

  test('PATH wins over the legacy folder and the download', () async {
    final system = await _executable(path.join(systemFolder.path, 'whisper-cli'));
    final legacy = Directory(path.join(root.path, 'support', 'whisper', 'bin'));
    await legacy.create(recursive: true);
    await _executable(path.join(legacy.path, 'whisper-cli'));
    final component = Directory(
      path.join(root.path, 'support', 'components', 'test-runtime'),
    );
    await component.create(recursive: true);
    await _executable(path.join(component.path, 'whisper-cli'));

    final components = componentsWith(pathValue: systemFolder.path);

    expect((await components.executable(runtime))?.path, system.path);
    expect(await components.systemAvailable(runtime), isTrue);
  });

  test('the legacy folder is next when PATH has nothing', () async {
    final legacy = Directory(path.join(root.path, 'support', 'whisper', 'bin'));
    await legacy.create(recursive: true);
    final file = await _executable(path.join(legacy.path, 'whisper-cli'));

    final components = componentsWith(pathValue: '');

    expect((await components.executable(runtime))?.path, file.path);
    expect(await components.systemAvailable(runtime), isTrue);
  });

  test('the downloaded component is the last resort', () async {
    final component = Directory(
      path.join(root.path, 'support', 'components', 'test-runtime'),
    );
    await component.create(recursive: true);
    final file = await _executable(path.join(component.path, 'whisper-cli'));

    final components = componentsWith(pathValue: '');

    expect((await components.executable(runtime))?.path, file.path);
    expect(
      await components.systemAvailable(runtime),
      isFalse,
      reason: 'a downloaded copy is not a system install',
    );
  });

  test('a model file is read from the legacy folder before the download', () async {
    final legacyFolder = Directory(
      path.join(root.path, 'support', 'translation', 'models'),
    );
    await legacyFolder.create(recursive: true);
    final legacy = File(path.join(legacyFolder.path, 'model.bin'));
    await legacy.writeAsString('legacy');
    final component = Directory(
      path.join(root.path, 'support', 'components', 'test-model'),
    );
    await component.create(recursive: true);
    await File(path.join(component.path, 'model.bin')).writeAsString('new');

    final components = componentsWith(pathValue: '');

    expect((await components.file(model, 'model.bin'))?.path, legacy.path);
    expect(await components.systemAvailable(model), isTrue);
  });
}

Future<File> _executable(String filePath) async {
  final file = File(filePath);
  await file.writeAsString('#!/bin/sh\n');
  await Process.run('chmod', ['755', file.path]);
  return file;
}
