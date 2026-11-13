import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/translation/local_model_installer.dart';
import 'package:tune/data/services/translation/translation_assets.dart';

/// Serves one canned byte body for the download.
class _BytesAdapter implements HttpClientAdapter {
  _BytesAdapter(this.bytes);

  final List<int> bytes;
  int calls = 0;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    lastRequest = options;
    final payload = Uint8List.fromList(bytes);
    return ResponseBody(
      Stream<Uint8List>.value(payload),
      200,
      headers: {
        Headers.contentLengthHeader: [payload.length.toString()],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Packs [files] into a zip the installer can extract.
List<int> _zipOf(Map<String, List<int>> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.addFile(ArchiveFile.bytes(entry.key, entry.value));
  }
  return ZipEncoder().encodeBytes(archive);
}

LocalModelInstaller _installerWith(Directory support, List<int> bytes) {
  return LocalModelInstaller(
    supportDirectory: support,
    dio: Dio()..httpClientAdapter = _BytesAdapter(bytes),
    baseUrl: 'https://example.test/releases',
    environment: const {},
  );
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_local_model_install');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a download that is not an archive fails and leaves no staging', () async {
    final installer = _installerWith(root, utf8.encode('not a zip'));

    await expectLater(installer.install(), throwsA(anything));

    expect(
      Directory(path.join(root.path, '.translation-staging')).existsSync(),
      isFalse,
    );
    expect(
      Directory(path.join(root.path, 'translation')).existsSync(),
      isFalse,
    );
  });

  test('an archive without the model is rejected and cleaned up', () async {
    final installer = _installerWith(
      root,
      _zipOf({
        'bin/llama-cli': utf8.encode('runtime'),
      }),
    );

    await expectLater(
      installer.install(),
      throwsA(
        isA<LocalModelInstallException>().having(
          (error) => error.message,
          'message',
          contains('no model'),
        ),
      ),
    );

    expect(
      Directory(path.join(root.path, '.translation-staging')).existsSync(),
      isFalse,
    );
  });

  test('a model of the wrong size is rejected', () async {
    final installer = _installerWith(
      root,
      _zipOf({
        'models/${TranslationAssets.modelFileName}': utf8.encode('short'),
        'bin/llama-cli': utf8.encode('runtime'),
      }),
    );

    await expectLater(
      installer.install(),
      throwsA(
        isA<LocalModelInstallException>().having(
          (error) => error.message,
          'message',
          contains('${TranslationAssets.modelBytes}'),
        ),
      ),
    );

    expect(
      Directory(path.join(root.path, '.translation-staging')).existsSync(),
      isFalse,
    );
  });

  test('sizeOnDisk counts the installed files, and remove() clears them',
      () async {
    final installer = LocalModelInstaller(
      supportDirectory: root,
      dio: Dio()..httpClientAdapter = _BytesAdapter(const []),
      baseUrl: 'https://example.test/releases',
      environment: const {},
    );
    final target = Directory(path.join(root.path, 'translation'));
    final models = Directory(path.join(target.path, 'models'))
      ..createSync(recursive: true);
    final bin = Directory(path.join(target.path, 'bin'))..createSync();
    File(path.join(models.path, TranslationAssets.modelFileName))
        .writeAsBytesSync(List<int>.filled(120, 3));
    File(path.join(bin.path, 'llama-cli')).writeAsBytesSync(
      List<int>.filled(30, 7),
    );
    final staging = Directory(path.join(root.path, '.translation-staging'))
      ..createSync();
    File(path.join(staging.path, 'component.zip')).writeAsBytesSync(
      List<int>.filled(5, 0),
    );
    final neighbour = Directory(path.join(root.path, 'other'))..createSync();

    expect(await installer.sizeOnDisk(), 150);

    await installer.remove();

    expect(await installer.sizeOnDisk(), 0);
    expect(target.existsSync(), isFalse);
    expect(staging.existsSync(), isFalse);
    expect(neighbour.existsSync(), isTrue, reason: 'remove only owns '
        'translation/, never the rest of the support folder');
  });

  test('an empty support folder has nothing on disk', () async {
    final installer = LocalModelInstaller(
      supportDirectory: Directory(path.join(root.path, 'missing')),
      dio: Dio()..httpClientAdapter = _BytesAdapter(const []),
      baseUrl: 'https://example.test/releases',
      environment: const {},
    );

    expect(await installer.sizeOnDisk(), 0);
    await installer.remove();
    expect(
      Directory(path.join(root.path, 'missing', 'translation')).existsSync(),
      isFalse,
    );
  });

  test('the download address is the release asset under the base URL',
      () async {
    final installer = LocalModelInstaller(
      supportDirectory: root,
      dio: Dio()..httpClientAdapter = _BytesAdapter(const []),
      baseUrl: 'https://example.test/releases/',
      environment: const {},
    );

    expect(
      installer.downloadUrl,
      'https://example.test/releases/${LocalModelInstaller.assetName}',
    );
  });

  test('the environment names the base URL when no argument does', () async {
    final installer = LocalModelInstaller(
      supportDirectory: root,
      dio: Dio()..httpClientAdapter = _BytesAdapter(const []),
      environment: const {
        'TUNE_TRANSLATION_BASE_URL': 'https://mirror.test/components',
      },
    );

    expect(
      installer.downloadUrl,
      'https://mirror.test/components/${LocalModelInstaller.assetName}',
    );
  });
}
