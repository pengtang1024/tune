import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_components.dart';
import 'package:tune/data/services/smart_lyrics/whisper_model_store.dart';

import 'fake_http_adapter.dart';

/// The models of the local channel (docs/smart-lyrics.md §6.2, M4): the
/// shared installer brings the file home, the registry's size and checksum
/// decide whether it may become the model.
void main() {
  late Directory root;
  late LocalComponentSpec spec;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_whisper_models');
    spec = LocalComponentSpec(
      id: 'lyrics-whisper-model-base',
      kind: LocalComponentKind.model,
      label: LocalComponentLabel.whisperModelBase,
      files: [
        LocalComponentFile(
          fileName: 'ggml-base.bin',
          url: 'https://example.test/ggml-base.bin',
          bytes: 11,
          sha256: _sha256Of('model bytes'),
        ),
      ],
      requiredFiles: const ['ggml-base.bin'],
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  WhisperModelStore storeWith(FakeHttpAdapter adapter) {
    return WhisperModelStore(
      components: LocalComponents(
        supportDirectory: root,
        environment: {'HOME': root.path},
        dio: Dio(BaseOptions(responseType: ResponseType.plain))
          ..httpClientAdapter = adapter,
      ),
      specOf: (_) => spec,
    );
  }

  test('a model that is not there yet is not found', () async {
    expect(await storeWith(FakeHttpAdapter()).findModel('base'), isNull);
  });

  test('a downloaded model lands under its own name', () async {
    final store = storeWith(FakeHttpAdapter()..body = 'model bytes');

    await store.download('base');

    final file = await store.findModel('base');
    expect(file, isNotNull);
    expect(await file!.readAsString(), 'model bytes');
  });

  test('a model that does not match the checksum is thrown away', () async {
    final store = WhisperModelStore(
      components: LocalComponents(
        supportDirectory: root,
        environment: {'HOME': root.path},
        dio: Dio(BaseOptions(responseType: ResponseType.plain))
          ..httpClientAdapter = (FakeHttpAdapter()..body = 'other bytes'),
      ),
      specOf: (_) => spec,
    );

    await expectLater(
      store.download('base'),
      throwsA(isA<WhisperModelException>()),
    );

    expect(
      await store.findModel('base'),
      isNull,
      reason: 'a wrong file never becomes the model — it would poison every '
          'song after it',
    );
  });

  test('removing the model returns the component to not installed',
      () async {
    final store = storeWith(FakeHttpAdapter()..body = 'model bytes');
    await store.download('base');
    expect(await store.findModel('base'), isNotNull);

    await store.remove('base');

    expect(await store.findModel('base'), isNull);
    expect(await store.sizeOnDisk('base'), 0);
  });

  test('the installed model reports the bytes it takes', () async {
    final store = storeWith(FakeHttpAdapter()..body = 'model bytes');
    await store.download('base');

    expect(await store.sizeOnDisk('base'), greaterThanOrEqualTo(11));
  });
}

/// The checksum of [text], matching what the registry would pin.
String _sha256Of(String text) {
  final digest = sha256.convert(utf8.encode(text));
  return digest.toString();
}
