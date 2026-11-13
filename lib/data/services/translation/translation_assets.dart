import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Whether the offline translation files can be used.
enum TranslationAssetProblem { none, modelMissing, modelCorrupt, binaryMissing }

class TranslationAssetStatus {
  final TranslationAssetProblem problem;

  const TranslationAssetStatus(this.problem);

  bool get ready => problem == TranslationAssetProblem.none;
}

/// The files the offline engine needs, and where the installer put them.
///
/// The model and the llama.cpp runtime are an optional component now. They
/// are downloaded into the application support directory; the copies that an
/// older release unpacked next to the executable are still read so an upgrade
/// does not break a working install.
class TranslationAssets {
  /// The release that was tested with this client.
  static const String binaryVersion = 'b12274';
  static const String modelFileName = 'qwen2.5-0.5b-instruct-q4_k_m.gguf';
  static const String modelSha256 =
      '74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db';
  static const int modelBytes = 491400032;

  final Directory root;
  final String supportPath;
  final bool userInstalled;
  final int expectedModelBytes;
  final String expectedModelSha256;

  TranslationAssets(
    this.root, {
    required this.supportPath,
    this.userInstalled = false,
    this.expectedModelBytes = modelBytes,
    this.expectedModelSha256 = modelSha256,
  });

  /// Finds the `translation/` directory to use.
  ///
  /// Order: explicit override, the copy the reader downloaded, the copy next
  /// to the executable from an older release, the repository when running
  /// from `flutter run`, then the support directory as a fallback.
  /// An explicit override is returned as-is so a broken path stays visible
  /// instead of silently falling back to another copy.
  static TranslationAssets resolve({
    required String executablePath,
    required String supportPath,
    Map<String, String>? environment,
    int maxParents = 6,
  }) {
    final env = environment ?? Platform.environment;
    final override = env['TUNE_TRANSLATION_DIR']?.trim();
    if (override != null && override.isNotEmpty) {
      return TranslationAssets(
        Directory(override),
        supportPath: supportPath,
      );
    }

    final installed = Directory(path.join(supportPath, 'translation'));
    if (_looksInstalled(installed)) {
      return TranslationAssets(
        installed,
        supportPath: supportPath,
        userInstalled: true,
      );
    }

    final executableDirectory = Directory(path.dirname(executablePath));
    final packaged = Directory(
      path.join(executableDirectory.path, 'translation'),
    );
    if (packaged.existsSync()) {
      return TranslationAssets(packaged, supportPath: supportPath);
    }

    var cursor = executableDirectory;
    for (var depth = 0; depth < maxParents; depth++) {
      final candidate = Directory(path.join(cursor.path, 'translation'));
      if (File(
        path.join(candidate.path, 'models', modelFileName),
      ).existsSync()) {
        return TranslationAssets(candidate, supportPath: supportPath);
      }
      final parent = cursor.parent;
      if (parent.path == cursor.path) break;
      cursor = parent;
    }

    return TranslationAssets(installed, supportPath: supportPath);
  }

  static bool _looksInstalled(Directory directory) {
    if (!directory.existsSync()) return false;
    if (File(path.join(directory.path, 'installed.json')).existsSync()) {
      return true;
    }
    return File(path.join(directory.path, 'models', modelFileName)).existsSync();
  }

  static Future<TranslationAssets> forApp() async {
    final support = await getApplicationSupportDirectory();
    return resolve(
      executablePath: Platform.resolvedExecutable,
      supportPath: support.path,
    );
  }

  Directory get binDirectory => Directory(path.join(root.path, 'bin'));

  File get modelFile => File(path.join(root.path, 'models', modelFileName));

  /// The `llama-cli` inside the unpacked runtime, or `null` when absent.
  Future<String?> findBinary() async {
    final directory = binDirectory;
    if (!await directory.exists()) return null;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && path.basename(entity.path) == 'llama-cli') {
        return entity.path;
      }
    }
    return null;
  }

  /// Checks presence and size, and the digest when [verifyDigest] is set.
  Future<TranslationAssetStatus> inspect({bool verifyDigest = false}) async {
    final model = modelFile;
    if (!await model.exists()) {
      return const TranslationAssetStatus(TranslationAssetProblem.modelMissing);
    }
    final length = await model.length();
    if (length != expectedModelBytes) {
      return const TranslationAssetStatus(TranslationAssetProblem.modelCorrupt);
    }
    if (verifyDigest) {
      final digest = await _digestOf(model.path, length);
      if (digest != expectedModelSha256) {
        return const TranslationAssetStatus(
          TranslationAssetProblem.modelCorrupt,
        );
      }
    }
    if (await findBinary() == null) {
      return const TranslationAssetStatus(
        TranslationAssetProblem.binaryMissing,
      );
    }
    return const TranslationAssetStatus(TranslationAssetProblem.none);
  }

  /// Bytes the installed component takes on disk.
  Future<int> installedSize() async {
    if (!await root.exists()) return 0;
    var total = 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}

/// Digests keyed by path, size and mtime, so repeated checks stay cheap.
final Map<String, String> _digestCache = {};

Future<String> _digestOf(String filePath, int length) async {
  final modified = (await File(filePath).lastModified()).millisecondsSinceEpoch;
  final key = '$filePath|$length|$modified';
  final cached = _digestCache[key];
  if (cached != null) return cached;
  final digest = await Isolate.run(() => _sha256Of(filePath));
  _digestCache[key] = digest;
  return digest;
}

Future<String> _sha256Of(String filePath) async {
  final digest = await sha256.bind(File(filePath).openRead()).first;
  return digest.toString();
}
