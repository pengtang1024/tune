import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/components/local_component.dart';

/// A component could not be downloaded, checked or unpacked.
class LocalComponentInstallException implements Exception {
  final String message;

  const LocalComponentInstallException(this.message);

  @override
  String toString() => message;
}

/// Downloads, checks, unpacks and removes components (docs/local-components.md).
///
/// One implementation serves every runtime and every model: the registry says
/// what to fetch, this class says how. A failed download leaves the previous
/// copy in place; a cancelled one leaves no staging behind.
class LocalComponentInstaller {
  final Directory supportDirectory;
  final Dio _dio;
  final Map<String, String> _environment;

  LocalComponentInstaller({
    required this.supportDirectory,
    Dio? dio,
    Map<String, String>? environment,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(minutes: 30),
             ),
           ),
       _environment = environment ?? Platform.environment;

  Directory get componentsRoot =>
      Directory(path.join(supportDirectory.path, 'components'));

  Directory directoryOf(LocalComponentSpec spec) =>
      Directory(path.join(componentsRoot.path, spec.id));

  Directory _stagingOf(LocalComponentSpec spec) =>
      Directory(path.join(componentsRoot.path, '.${spec.id}.staging'));

  /// Where [file] is fetched from, in order.
  ///
  /// `TUNE_COMPONENT_BASE_URL` replaces every source with
  /// `<base>/<id>/<file name>` — one self-hosted address, no fallbacks. With
  /// no override the canonical URL comes first and the mirrors after it, and
  /// all of them must match the same pinned bytes and sha256.
  List<String> sourcesOf(LocalComponentSpec spec, LocalComponentFile file) {
    final base = _environment['TUNE_COMPONENT_BASE_URL']?.trim();
    if (base != null && base.isNotEmpty) {
      return [
        '${base.replaceFirst(RegExp(r'/+$'), '')}/${spec.id}/${file.fileName}',
      ];
    }
    return file.sources;
  }

  /// Fetches, checks and swaps in [spec].
  Future<void> install(
    LocalComponentSpec spec, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await componentsRoot.create(recursive: true);
    final staging = _stagingOf(spec);
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    try {
      final downloads = Directory(path.join(staging.path, 'downloads'));
      await downloads.create(recursive: true);
      final total = spec.totalBytes;
      var before = 0;
      for (final file in spec.files) {
        await _downloadOne(
          spec: spec,
          file: file,
          target: File(path.join(downloads.path, file.fileName)),
          cancelToken: cancelToken,
          onProgress: onProgress,
          before: before,
          total: total,
        );
        before += file.bytes;
      }

      final content = Directory(path.join(staging.path, 'content'));
      await content.create(recursive: true);
      if (spec.archive == LocalComponentArchive.none) {
        for (final file in spec.files) {
          await File(
            path.join(downloads.path, file.fileName),
          ).rename(path.join(content.path, file.fileName));
        }
      } else {
        for (final file in spec.files) {
          await _extract(File(path.join(downloads.path, file.fileName)), content, spec.archive);
        }
      }

      final payload = await _payloadRoot(content, spec);
      await _verifyPayload(spec, payload);
      await _swap(spec, payload);
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  /// Removes the downloaded copy. A copy the system or an older release
  /// provided is not ours and stays.
  Future<void> remove(LocalComponentSpec spec) async {
    final directory = directoryOf(spec);
    if (await directory.exists()) await directory.delete(recursive: true);
    final staging = _stagingOf(spec);
    if (await staging.exists()) await staging.delete(recursive: true);
  }

  /// Bytes the downloaded copy takes, or 0 when it is not installed.
  Future<int> sizeOnDisk(LocalComponentSpec spec) async {
    final directory = directoryOf(spec);
    if (!await directory.exists()) return 0;
    return _sizeOf(directory);
  }

  /// Whether the downloaded copy is whole, and how much it takes.
  Future<({bool installed, int bytes})> inspect(
    LocalComponentSpec spec,
  ) async {
    final directory = directoryOf(spec);
    if (!await directory.exists()) return (installed: false, bytes: 0);
    final complete = await _payloadComplete(spec, directory);
    if (!complete) return (installed: false, bytes: 0);
    return (installed: true, bytes: await _sizeOf(directory));
  }

  /// Tries every source of one file until one passes the pinned length and
  /// digest. A cancellation stops the loop at once; every other failure is
  /// collected so the last error names the hosts that were tried.
  Future<void> _downloadOne({
    required LocalComponentSpec spec,
    required LocalComponentFile file,
    required File target,
    required CancelToken? cancelToken,
    required void Function(int received, int total)? onProgress,
    required int before,
    required int total,
  }) async {
    final failures = <String>[];
    for (final url in sourcesOf(spec, file)) {
      try {
        if (await target.exists()) await target.delete();
        await _dio.download(
          url,
          target.path,
          cancelToken: cancelToken,
          deleteOnError: true,
          onReceiveProgress: (received, _) {
            onProgress?.call(before + received, total);
          },
        );
        await _verifyFile(file, target);
        return;
      } on LocalComponentInstallException catch (error) {
        failures.add('${_sourceName(url)}: ${error.message}');
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) rethrow;
        failures.add('${_sourceName(url)}: ${_dioReason(error)}');
      }
    }
    throw LocalComponentInstallException(
      '${file.fileName} could not be downloaded from any source'
      '${failures.isEmpty ? '' : ' (${failures.join('; ')})'}',
    );
  }

  /// The host as the reader sees it; a malformed URL stays whole.
  static String _sourceName(String url) => Uri.tryParse(url)?.host ?? url;

  static String _dioReason(DioException error) {
    final status = error.response?.statusCode;
    if (status != null) return 'HTTP $status';
    return error.message ?? error.type.name;
  }

  Future<void> _verifyFile(
    LocalComponentFile file,
    File downloaded,
  ) async {
    final bytes = await downloaded.length();
    if (bytes != file.bytes) {
      throw LocalComponentInstallException(
        '${file.fileName} has $bytes bytes, expected ${file.bytes}',
      );
    }
    final digest = await _sha256Of(downloaded);
    if (digest != file.sha256.toLowerCase()) {
      throw LocalComponentInstallException(
        '${file.fileName} does not match the published sha256',
      );
    }
  }

  Future<void> _verifyPayload(
    LocalComponentSpec spec,
    Directory payload,
  ) async {
    for (final name in spec.requiredFiles) {
      if (!await File(path.join(payload.path, name)).exists()) {
        throw LocalComponentInstallException(
          'the component has no $name',
        );
      }
    }
    if (spec.isRuntime && spec.executable != null) {
      final executable = await _findExecutable(payload, spec.executable!);
      if (executable == null) {
        throw LocalComponentInstallException(
          'the component has no ${spec.executable}',
        );
      }
      if (Platform.isLinux ||
          Platform.isMacOS ||
          Platform.isAndroid ||
          Platform.isIOS) {
        await Process.run('chmod', ['755', executable.path]);
      }
    }
  }

  Future<void> _swap(LocalComponentSpec spec, Directory payload) async {
    final target = directoryOf(spec);
    final backup = Directory(
      path.join(componentsRoot.path, '.${spec.id}.old'),
    );
    if (await backup.exists()) await backup.delete(recursive: true);
    final hadTarget = await target.exists();
    if (hadTarget) await target.rename(backup.path);
    try {
      await payload.rename(target.path);
    } catch (error) {
      if (hadTarget && await backup.exists()) await backup.rename(target.path);
      rethrow;
    }
    if (await backup.exists()) await backup.delete(recursive: true);
    await File(path.join(target.path, 'installed.json')).writeAsString(
      jsonEncode({
        'id': spec.id,
        'files': [for (final file in spec.files) file.fileName],
        'installedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// The folder that is the component: a single top-level folder is stripped,
  /// the way every release archive wraps its payload.
  Future<Directory> _payloadRoot(
    Directory content,
    LocalComponentSpec spec,
  ) async {
    final entries = await content.list().toList();
    if (entries.length != 1 || entries.single is! Directory) return content;
    final nested = entries.single as Directory;
    if (spec.executable == null) return nested;
    final found = await _findExecutable(nested, spec.executable!);
    return found == null ? content : nested;
  }

  Future<bool> _payloadComplete(
    LocalComponentSpec spec,
    Directory directory,
  ) async {
    for (final name in spec.requiredFiles) {
      if (!await File(path.join(directory.path, name)).exists()) return false;
    }
    if (spec.isRuntime && spec.executable != null) {
      return await _findExecutable(directory, spec.executable!) != null;
    }
    return true;
  }

  Future<File?> _findExecutable(Directory root, String name) async {
    if (!await root.exists()) return null;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File && path.basename(entity.path) == name) return entity;
    }
    return null;
  }

  Future<int> _sizeOf(Directory directory) async {
    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> _extract(
    File archive,
    Directory output,
    LocalComponentArchive kind,
  ) async {
    switch (kind) {
      case LocalComponentArchive.zip:
        await extractFileToDisk(archive.path, output.path, verify: true);
      case LocalComponentArchive.tarGz:
        await _extractTar(
          TarDecoder().decodeBytes(
            GZipDecoder().decodeBytes(await archive.readAsBytes()),
          ),
          output,
        );
      case LocalComponentArchive.tarBz2:
        await _extractTar(
          TarDecoder().decodeBytes(
            BZip2Decoder().decodeBytes(await archive.readAsBytes()),
          ),
          output,
        );
      case LocalComponentArchive.tarXz:
        await _extractTar(
          TarDecoder().decodeBytes(
            XZDecoder().decodeBytes(await archive.readAsBytes()),
          ),
          output,
        );
      case LocalComponentArchive.none:
        throw const LocalComponentInstallException(
          'a plain file is not an archive',
        );
    }
  }

  Future<void> _extractTar(Archive archive, Directory output) async {
    await extractArchiveToDisk(archive, output.path);
  }

  static Future<String> _sha256Of(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
