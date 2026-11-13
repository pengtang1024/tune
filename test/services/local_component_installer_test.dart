import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_installer.dart';

import 'fake_http_adapter.dart';

/// One installer serves every component (docs/local-components.md §2): the
/// bytes are checked before anything becomes the component, and a failure
/// leaves the old copy alone.
void main() {
  const body = 'model bytes';
  late Directory root;
  late LocalComponentSpec spec;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_components');
    spec = LocalComponentSpec(
      id: 'test-model',
      kind: LocalComponentKind.model,
      label: LocalComponentLabel.translationModel,
      files: [
        LocalComponentFile(
          fileName: 'model.bin',
          url: 'https://example.test/model.bin',
          bytes: body.length,
          sha256: _sha256Of(body),
        ),
      ],
      requiredFiles: const ['model.bin'],
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  LocalComponentInstaller installerWith(FakeHttpAdapter adapter) =>
      LocalComponentInstaller(
        supportDirectory: root,
        environment: const {},
        dio: Dio(BaseOptions(responseType: ResponseType.plain))
          ..httpClientAdapter = adapter,
      );

  test('a checked file becomes the component and reports its bytes', () async {
    final installer = installerWith(FakeHttpAdapter()..body = body);

    await installer.install(spec);

    final payload = File('${installer.directoryOf(spec).path}/model.bin');
    expect(await payload.exists(), isTrue);
    expect(await payload.readAsString(), body);

    final state = await installer.inspect(spec);
    expect(state.installed, isTrue);
    expect(state.bytes, greaterThanOrEqualTo(body.length));
    expect(await installer.sizeOnDisk(spec), state.bytes);
  });

  test('a file whose digest does not match never becomes the component', () async {
    final installer = installerWith(FakeHttpAdapter()..body = 'other bytes');

    await expectLater(
      installer.install(spec),
      throwsA(isA<LocalComponentInstallException>()),
    );

    expect((await installer.inspect(spec)).installed, isFalse);
  });

  test('a component missing a required file is rejected', () async {
    final installer = installerWith(FakeHttpAdapter()..body = body);
    final broken = LocalComponentSpec(
      id: 'broken-model',
      kind: LocalComponentKind.model,
      label: LocalComponentLabel.translationModel,
      files: spec.files,
      requiredFiles: const ['other.bin'],
    );

    await expectLater(
      installer.install(broken),
      throwsA(isA<LocalComponentInstallException>()),
    );

    expect((await installer.inspect(broken)).installed, isFalse);
  });

  test('removing the component leaves no staging behind', () async {
    final installer = installerWith(FakeHttpAdapter()..body = body);
    await installer.install(spec);
    expect((await installer.inspect(spec)).installed, isTrue);

    await installer.remove(spec);

    expect((await installer.inspect(spec)).installed, isFalse);
    expect(await installer.sizeOnDisk(spec), 0);
    expect(
      await Directory('${root.path}/components').list().isEmpty,
      isTrue,
      reason: 'the staging folder is dropped with the component',
    );
  });

  test('progress climbs to the full size', () async {
    final installer = installerWith(FakeHttpAdapter()..body = body);
    final seen = <int>[];

    await installer.install(
      spec,
      onProgress: (received, total) {
        expect(total, body.length);
        seen.add(received);
      },
    );

    expect(seen, isNotEmpty);
    expect(seen.last, body.length);
  });
}

String _sha256Of(String text) => sha256.convert(utf8.encode(text)).toString();
