import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/whisper_model_store.dart';

import 'fake_http_adapter.dart';

/// The models of the local channel (docs/smart-lyrics.md §6.2, M4): the
/// app downloads them from the whisper.cpp home, checks them against the
/// checksum the home publishes, and keeps them where the engine looks.
void main() {
  late Directory root;
  late WhisperModelStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_whisper_models');
    store = WhisperModelStore(
      root: root,
      dio: Dio(BaseOptions(responseType: ResponseType.plain)),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a model that is not there yet is not found', () async {
    expect(await store.findModel('base'), isNull);
  });

  test('a downloaded model lands under its own name', () async {
    final adapter = FakeHttpAdapter()..body = 'model bytes';
    store = WhisperModelStore(
      root: root,
      dio: Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter,
    );

    await store.download('base', checksum: _sha256Of('model bytes'));

    final file = await store.findModel('base');
    expect(file, isNotNull);
    expect(await file!.readAsString(), 'model bytes');
  });

  test('a model that does not match the checksum is thrown away', () async {
    final adapter = FakeHttpAdapter()..body = 'model bytes';
    store = WhisperModelStore(
      root: root,
      dio: Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter,
    );

    await expectLater(
      store.download('base', checksum: _sha256Of('other bytes')),
      throwsA(isA<WhisperModelException>()),
    );

    expect(await store.findModel('base'), isNull, reason: 'a wrong file never '
        'becomes the model — it would poison every song after it');
  });

  test('the answer of the home says which file is which', () async {
    final adapter = FakeHttpAdapter()
      ..body = jsonEncode([
        {
          'type': 'file',
          'path': 'ggml-base.bin',
          'lfs': {'sha256': _sha256Of('model bytes'), 'size': 11},
        },
      ]);
    store = WhisperModelStore(
      root: root,
      dio: Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter,
    );

    final checksum = await store.checksumOf('base');

    expect(checksum, _sha256Of('model bytes'));
  });

  test('a home that says nothing about the model is no checksum', () async {
    final adapter = FakeHttpAdapter()..body = jsonEncode([
      {'type': 'file', 'path': 'ggml-tiny.bin', 'lfs': {'sha256': 'x'}},
    ]);
    store = WhisperModelStore(
      root: root,
      dio: Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter,
    );

    expect(await store.checksumOf('base'), isNull);
  });

  test('the size the home publishes is told apart from the checksum', () async {
    final adapter = FakeHttpAdapter()
      ..body = jsonEncode([
        {
          'type': 'file',
          'path': 'ggml-base.bin',
          'lfs': {'sha256': _sha256Of('model bytes'), 'size': 11},
        },
      ]);
    store = WhisperModelStore(
      root: root,
      dio: Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter,
    );

    expect(await store.sizeOf('base'), 11);
  });
}

/// The checksum of [text], the way the home publishes it.
String _sha256Of(String text) {
  final digest = sha256.convert(utf8.encode(text));
  return digest.toString();
}
