import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/translation/translation_assets.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('tune-translation-assets');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  TranslationAssets assetsFor(String body, {int? bytes, String? sha}) {
    final root = Directory(path.join(temp.path, 'translation'));
    final model = File(
      path.join(root.path, 'models', TranslationAssets.modelFileName),
    )..createSync(recursive: true);
    model.writeAsStringSync(body);
    return TranslationAssets(
      root,
      supportPath: temp.path,
      expectedModelBytes: bytes ?? model.lengthSync(),
      expectedModelSha256:
          sha ?? sha256.convert(model.readAsBytesSync()).toString(),
    );
  }

  void createBinary(Directory root) {
    File(path.join(root.path, 'bin', 'llama-b12274', 'llama-cli'))
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/sh\n');
  }

  test('missing model is reported as missing', () async {
    final assets = TranslationAssets(
      Directory(path.join(temp.path, 'translation')),
      supportPath: temp.path,
      expectedModelBytes: 4,
      expectedModelSha256: 'unused',
    );

    final status = await assets.inspect();

    expect(status.problem, TranslationAssetProblem.modelMissing);
    expect(status.ready, isFalse);
  });

  test('an LFS pointer is rejected by the size check', () async {
    final assets = assetsFor(
      'version https://git-lfs.github.com/spec/v1\n'
      'oid sha256:74a4\nsize 491400032\n',
      bytes: TranslationAssets.modelBytes,
    );
    createBinary(assets.root);

    final status = await assets.inspect();

    expect(status.problem, TranslationAssetProblem.modelCorrupt);
  });

  test('a model of the right size but wrong digest is corrupt', () async {
    final assets = assetsFor('model-body', sha: 'not-the-digest');
    createBinary(assets.root);

    final status = await assets.inspect(verifyDigest: true);

    expect(status.problem, TranslationAssetProblem.modelCorrupt);
  });

  test('a valid model without llama-cli reports the missing binary', () async {
    final assets = assetsFor('model-body');

    final status = await assets.inspect(verifyDigest: true);

    expect(status.problem, TranslationAssetProblem.binaryMissing);
  });

  test('a matching model and binary are ready', () async {
    final assets = assetsFor('model-body');
    createBinary(assets.root);

    final status = await assets.inspect(verifyDigest: true);

    expect(status.problem, TranslationAssetProblem.none);
    expect(status.ready, isTrue);
  });

  group('resolve', () {
    test(
      'returns TUNE_TRANSLATION_DIR as-is, even when a copy is installed',
      () {
        final override = path.join(temp.path, 'elsewhere');
        final support = path.join(temp.path, 'support');
        File(
          path.join(support, 'translation', 'installed.json'),
        ).createSync(recursive: true);

        final assets = TranslationAssets.resolve(
          executablePath: path.join(temp.path, 'app', 'tune'),
          supportPath: support,
          environment: {'TUNE_TRANSLATION_DIR': override},
        );

        expect(assets.root.path, override);
        expect(assets.supportPath, support);
        expect(assets.userInstalled, isFalse);
      },
    );

    test('prefers an installed copy in the support directory', () {
      final support = path.join(temp.path, 'support');
      final installed = Directory(path.join(support, 'translation'))
        ..createSync(recursive: true);
      File(path.join(installed.path, 'installed.json')).writeAsStringSync('{}');
      final executableDirectory = path.join(temp.path, 'bundle');
      Directory(
        path.join(executableDirectory, 'translation'),
      ).createSync(recursive: true);

      final assets = TranslationAssets.resolve(
        executablePath: path.join(executableDirectory, 'tune'),
        supportPath: support,
        environment: const {},
      );

      expect(assets.root.path, installed.path);
      expect(assets.userInstalled, isTrue);
    });

    test('a model in the support directory counts as installed', () {
      final support = path.join(temp.path, 'support');
      final installed = Directory(path.join(support, 'translation'))
        ..createSync(recursive: true);
      File(
        path.join(installed.path, 'models', TranslationAssets.modelFileName),
      ).createSync(recursive: true);
      final executableDirectory = path.join(temp.path, 'bundle');
      Directory(
        path.join(executableDirectory, 'translation'),
      ).createSync(recursive: true);

      final assets = TranslationAssets.resolve(
        executablePath: path.join(executableDirectory, 'tune'),
        supportPath: support,
        environment: const {},
      );

      expect(assets.root.path, installed.path);
      expect(assets.userInstalled, isTrue);
    });

    test('prefers the translation directory next to the executable', () {
      final executable = path.join(temp.path, 'bundle', 'tune');
      Directory(
        path.join(temp.path, 'bundle', 'translation'),
      ).createSync(recursive: true);

      final assets = TranslationAssets.resolve(
        executablePath: executable,
        supportPath: path.join(temp.path, 'support'),
        environment: const {},
      );

      expect(assets.root.path, path.join(temp.path, 'bundle', 'translation'));
    });

    test('walks up to the repository when run from the build directory', () {
      final repository = Directory(path.join(temp.path, 'repo'));
      final model = File(
        path.join(
          repository.path,
          'translation',
          'models',
          TranslationAssets.modelFileName,
        ),
      )..createSync(recursive: true);
      model.writeAsStringSync('body');

      final assets = TranslationAssets.resolve(
        executablePath: path.join(
          repository.path,
          'build',
          'linux',
          'x64',
          'debug',
          'bundle',
          'tune',
        ),
        supportPath: path.join(temp.path, 'support'),
        environment: const {},
      );

      expect(assets.root.path, path.join(repository.path, 'translation'));
    });

    test('falls back to the support directory', () {
      final support = path.join(temp.path, 'support');

      final assets = TranslationAssets.resolve(
        executablePath: path.join(temp.path, 'bundle', 'tune'),
        supportPath: support,
        environment: const {},
      );

      expect(assets.root.path, path.join(support, 'translation'));
    });
  });
}
