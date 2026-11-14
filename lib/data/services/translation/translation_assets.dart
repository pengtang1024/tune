import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_components.dart';

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

  /// The default model: what a fresh component download brings home.
  static String get modelFileName =>
      LocalComponentRegistry.translationModel.requiredFiles.first;
  static String get modelSha256 =>
      LocalComponentRegistry.translationModel.files.first.sha256;
  static int get modelBytes =>
      LocalComponentRegistry.translationModel.files.first.bytes;

  final Directory root;
  final String supportPath;
  final bool userInstalled;

  /// Test overrides; production reads the digest from the registry.
  final int? expectedModelBytes;
  final String? expectedModelSha256;

  File? _componentModel;
  LocalComponentSpec? _componentModelSpec;
  String? _componentBinary;
  Directory? _componentBinDirectory;

  TranslationAssets(
    this.root, {
    required this.supportPath,
    this.userInstalled = false,
    this.expectedModelBytes,
    this.expectedModelSha256,
  });

  /// Lets an older copy stay the first choice while the downloaded component
  /// fills in when neither the folder nor the system has the file.
  ///
  /// Models are tried in tier order (default, low-memory, quality), so a
  /// reader who downloaded one alternative still has a working engine.
  Future<void> useComponents(LocalComponents components) async {
    if (_localModel() == null) {
      for (final spec in LocalComponentRegistry.translationModels) {
        final found = await components.file(spec, spec.requiredFiles.first);
        if (found != null) {
          _componentModel = found;
          _componentModelSpec = spec;
          break;
        }
      }
    }
    final binary = await _binaryIn(binDirectory);
    final componentBinary = binary == null
        ? await components.executable(LocalComponentRegistry.translationRuntime)
        : null;
    _componentBinary = binary ?? componentBinary?.path;
    if (componentBinary != null) {
      _componentBinDirectory = componentBinary.parent;
    }
  }

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
      if (_containsModel(candidate)) {
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
    return _containsModel(directory);
  }

  /// Whether any translation tier sits in `<directory>/models`.
  static bool _containsModel(Directory directory) {
    for (final spec in LocalComponentRegistry.translationModels) {
      final file = File(
        path.join(directory.path, 'models', spec.requiredFiles.first),
      );
      if (file.existsSync()) return true;
    }
    return false;
  }

  static Future<TranslationAssets> forApp() async {
    final support = await getApplicationSupportDirectory();
    return resolve(
      executablePath: Platform.resolvedExecutable,
      supportPath: support.path,
    );
  }

  Directory get binDirectory =>
      _componentBinDirectory ?? Directory(path.join(root.path, 'bin'));

  /// The model the engine runs: the first tier found under `models/`, or the
  /// downloaded component, or the default path when neither exists.
  File get modelFile =>
      _localModel()?.file ??
      File(path.join(root.path, 'models', modelFileName));

  /// The engine's cache key follows the model that is actually loaded.
  String get modelName => path.basename(modelFile.path);

  _InstalledModel? _localModel() {
    if (_componentModel != null) {
      return _InstalledModel(
        _componentModel!,
        _componentModelSpec ?? LocalComponentRegistry.translationModel,
      );
    }
    for (final spec in LocalComponentRegistry.translationModels) {
      final file = File(
        path.join(root.path, 'models', spec.requiredFiles.first),
      );
      if (file.existsSync()) return _InstalledModel(file, spec);
    }
    return null;
  }

  /// The `llama-cli` the engine runs, or `null` when absent.
  Future<String?> findBinary() async {
    if (_componentBinary != null) return _componentBinary;
    return _binaryIn(binDirectory);
  }

  static Future<String?> _binaryIn(Directory directory) async {
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
    final installed = _localModel();
    if (installed == null) {
      return const TranslationAssetStatus(TranslationAssetProblem.modelMissing);
    }
    final model = installed.file;
    final length = await model.length();
    final expectedBytes =
        expectedModelBytes ?? installed.spec.files.first.bytes;
    if (length != expectedBytes) {
      return const TranslationAssetStatus(TranslationAssetProblem.modelCorrupt);
    }
    if (verifyDigest) {
      final expectedSha =
          expectedModelSha256 ?? installed.spec.files.first.sha256;
      final digest = await _digestOf(model.path, length);
      if (digest != expectedSha) {
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

/// A model file together with the tier it came from.
class _InstalledModel {
  final File file;
  final LocalComponentSpec spec;

  const _InstalledModel(this.file, this.spec);
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
