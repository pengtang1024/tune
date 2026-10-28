import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/whisper_assets.dart';

/// Where the local channel finds what it needs (docs/smart-lyrics.md §6.2,
/// M4): a binary the system already has comes first — a download is the
/// fallback, not the way in.
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_whisper_assets');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// Writes a stand-in binary and makes it executable.
  Future<File> binaryIn(Directory folder, String name) async {
    final file = File('${folder.path}/$name');
    await file.writeAsString('#!/usr/bin/env bash\nexit 0');
    await Process.run('chmod', ['+x', file.path]);
    return file;
  }

  test('a binary the system has comes first', () async {
    final installed = await binaryIn(root, 'whisper-cli');
    final downloaded = await binaryIn(
      Directory('${root.path}/app')..createSync(recursive: true),
      'whisper-cli',
    );

    final assets = WhisperAssets(
      systemFolders: [root.path],
      appFolder: '${root.path}/app',
      modelsFolder: '${root.path}/models',
    );

    expect((await assets.findBinary())?.path, installed.path);
    expect(
      (await assets.findBinary())?.path,
      isNot(downloaded.path),
    );
  });

  test('without a system binary the app one is used', () async {
    final downloaded = await binaryIn(
      Directory('${root.path}/app')..createSync(recursive: true),
      'whisper-cli',
    );

    final assets = WhisperAssets(
      systemFolders: [root.path],
      appFolder: '${root.path}/app',
      modelsFolder: '${root.path}/models',
    );

    expect((await assets.findBinary())?.path, downloaded.path);
  });

  test('a binary that is there but cannot be run is not a binary', () async {
    final file = File('${root.path}/whisper-cli')
      ..writeAsString('not a program');

    final assets = WhisperAssets(
      systemFolders: [root.path],
      appFolder: '${root.path}/app',
      modelsFolder: '${root.path}/models',
    );

    expect(await assets.findBinary(), isNull);
    expect(file.existsSync(), isTrue);
  });

  test('the names the whisper binary answers to are all looked for', () async {
    final installed = await binaryIn(root, 'whisper-cpp');

    final assets = WhisperAssets(
      systemFolders: [root.path],
      appFolder: '${root.path}/app',
      modelsFolder: '${root.path}/models',
    );

    expect((await assets.findBinary())?.path, installed.path);
  });

  test('the model of a name is looked up beside the app folder', () async {
    final models = Directory('${root.path}/models')..createSync(recursive: true);
    final file = File('${models.path}/ggml-base.bin')
      ..writeAsStringSync('model');

    final assets = WhisperAssets(
      systemFolders: const [],
      appFolder: '${root.path}/app',
      modelsFolder: models.path,
    );

    expect((await assets.findModel('base'))?.path, file.path);
    expect(await assets.findModel('small'), isNull);
  });
}
