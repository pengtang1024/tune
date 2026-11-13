import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/translation/translation_assets.dart';

/// Downloads and removes the optional local translation component.
///
/// The release archive and the component are separate: an update replaces the
/// application, while this directory lives in the application support folder
/// and survives the update.
class LocalModelInstaller {
  static const String assetName =
      'tune-translation-qwen2.5-0.5b-b12274.zip';
  static const String defaultBaseUrl =
      'https://github.com/pengtang1024/tune/releases/latest/download';

  final Directory supportDirectory;
  final Dio _dio;
  final String _baseUrl;

  LocalModelInstaller({
    required this.supportDirectory,
    Dio? dio,
    String? baseUrl,
    Map<String, String>? environment,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(minutes: 30),
             ),
           ),
       _baseUrl = _resolveBaseUrl(baseUrl, environment);

  Directory get _target => Directory(
    path.join(supportDirectory.path, 'translation'),
  );

  Directory get _staging => Directory(
    path.join(supportDirectory.path, '.translation-staging'),
  );

  File get _archive => File(path.join(_staging.path, 'component.zip'));

  String get downloadUrl =>
      '${_baseUrl.replaceFirst(RegExp(r'/+$'), '')}/$assetName';

  /// Downloads, verifies and swaps in the component.
  ///
  /// The callback receives bytes received and the total when the server sends
  /// a length. Cancelling the token stops the download and leaves the old
  /// component untouched.
  Future<void> install({
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await supportDirectory.create(recursive: true);
    if (await _staging.exists()) await _staging.delete(recursive: true);
    await _staging.create(recursive: true);

    try {
      await _dio.download(
        downloadUrl,
        _archive.path,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      final extracted = Directory(path.join(_staging.path, 'extracted'));
      await extractFileToDisk(_archive.path, extracted.path, verify: true);
      final payload = await _payloadRoot(extracted);
      await _verify(payload);

      final backup = Directory(
        path.join(supportDirectory.path, '.translation-old'),
      );
      if (await backup.exists()) await backup.delete(recursive: true);
      final hadTarget = await _target.exists();
      if (hadTarget) await _target.rename(backup.path);
      try {
        await payload.rename(_target.path);
      } catch (error) {
        if (hadTarget && await backup.exists()) {
          await backup.rename(_target.path);
        }
        rethrow;
      }
      if (await backup.exists()) await backup.delete(recursive: true);
      await File(
        path.join(_target.path, 'installed.json'),
      ).writeAsString(jsonEncode({
        'version': TranslationAssets.binaryVersion,
        'model': TranslationAssets.modelFileName,
        'installedAt': DateTime.now().toIso8601String(),
      }));
    } finally {
      if (await _staging.exists()) await _staging.delete(recursive: true);
    }
  }

  /// Removes the downloaded component. A copy that shipped with an older
  /// application is not touched: this only deletes [supportDirectory].
  Future<void> remove() async {
    if (await _target.exists()) await _target.delete(recursive: true);
    if (await _staging.exists()) await _staging.delete(recursive: true);
  }

  /// Bytes the component takes, or 0 when it is not installed.
  Future<int> sizeOnDisk() async {
    if (!await _target.exists()) return 0;
    var total = 0;
    await for (final entity in _target.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<Directory> _payloadRoot(Directory extracted) async {
    final nested = Directory(path.join(extracted.path, 'translation'));
    if (await File(
      path.join(nested.path, 'models', TranslationAssets.modelFileName),
    ).exists()) {
      return nested;
    }
    return extracted;
  }

  Future<void> _verify(Directory payload) async {
    final model = File(
      path.join(payload.path, 'models', TranslationAssets.modelFileName),
    );
    if (!await model.exists()) {
      throw const LocalModelInstallException('the component has no model');
    }
    final bytes = await model.length();
    if (bytes != TranslationAssets.modelBytes) {
      throw LocalModelInstallException(
        'the model has $bytes bytes, expected ${TranslationAssets.modelBytes}',
      );
    }
    var found = false;
    final bin = Directory(path.join(payload.path, 'bin'));
    if (await bin.exists()) {
      await for (final entity in bin.list(recursive: true)) {
        if (entity is File && path.basename(entity.path) == 'llama-cli') {
          found = true;
          break;
        }
      }
    }
    if (!found) {
      throw const LocalModelInstallException('the component has no llama-cli');
    }
  }

  static String _resolveBaseUrl(
    String? explicit,
    Map<String, String>? environment,
  ) {
    final fromArgument = explicit?.trim();
    if (fromArgument != null && fromArgument.isNotEmpty) return fromArgument;
    final env = environment ?? Platform.environment;
    final fromEnv = env['TUNE_TRANSLATION_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return defaultBaseUrl;
  }
}

class LocalModelInstallException implements Exception {
  final String message;

  const LocalModelInstallException(this.message);

  @override
  String toString() => message;
}
