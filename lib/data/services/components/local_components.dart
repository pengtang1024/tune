import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_installer.dart';

/// Finds a component's binary or files, preferring what the machine already
/// has (docs/local-components.md §3).
///
/// Order is fixed: the system (PATH and the usual user folders), the folders
/// an older release wrote, then the downloaded component. The download is the
/// fallback; it never hides a working system install.
class LocalComponents {
  final Directory supportDirectory;

  /// The folder the app runs from, for the copies an older release unpacked
  /// beside the executable.
  final Directory? executableDirectory;

  final Map<String, String> environment;

  /// Lets a test hand the installer a client with a fake transport.
  final Dio? _dio;

  late final LocalComponentInstaller installer = LocalComponentInstaller(
    supportDirectory: supportDirectory,
    environment: environment,
    dio: _dio,
  );

  LocalComponents({
    required this.supportDirectory,
    this.executableDirectory,
    Map<String, String>? environment,
    Dio? dio,
  }) : environment = environment ?? Platform.environment,
       _dio = dio;

  /// The program of a runtime, `null` when neither the system nor the
  /// component provides it.
  Future<File?> executable(LocalComponentSpec spec) async {
    if (!spec.isRuntime || spec.executable == null) return null;
    final name = spec.executable!;
    final names = spec.systemNames.isEmpty ? [name] : spec.systemNames;

    for (final folder in _systemFolders) {
      for (final candidate in names) {
        final file = File(path.join(folder, candidate));
        if (await isRunnable(file)) return file;
      }
    }
    for (final probe in spec.systemPaths) {
      final expanded = _expand(probe);
      final file = File(expanded);
      if (await isRunnable(file)) return file;
      final folder = Directory(expanded);
      if (await folder.exists()) {
        for (final candidate in names) {
          final found = File(path.join(folder.path, candidate));
          if (await isRunnable(found)) return found;
        }
      }
    }
    for (final base in _legacyRoots) {
      for (final relative in spec.legacyDirectories) {
        final folder = Directory(path.join(base.path, relative));
        for (final candidate in names) {
          final found = File(path.join(folder.path, candidate));
          if (await isRunnable(found)) return found;
        }
      }
    }
    return _findInComponent(spec, name);
  }

  /// A file of a model, `null` when it is neither on the machine nor
  /// downloaded.
  Future<File?> file(LocalComponentSpec spec, String name) async {
    for (final relative in spec.legacyFiles) {
      if (path.basename(relative) != name) continue;
      for (final base in _legacyRoots) {
        final file = File(path.join(base.path, relative));
        if (await file.exists()) return file;
      }
    }
    for (final probe in spec.systemPaths) {
      final folder = Directory(_expand(probe));
      if (!await folder.exists()) continue;
      final file = File(path.join(folder.path, name));
      if (await file.exists()) return file;
    }
    final file = File(path.join(installer.directoryOf(spec).path, name));
    return await file.exists() ? file : null;
  }

  /// The folder of a model (SenseVoice holds several files), `null` when it
  /// is neither on the machine nor downloaded whole.
  Future<Directory?> directory(LocalComponentSpec spec) async {
    for (final probe in spec.systemPaths) {
      final folder = Directory(_expand(probe));
      if (await folder.exists()) return folder;
    }
    for (final base in _legacyRoots) {
      for (final relative in spec.legacyDirectories) {
        final folder = Directory(path.join(base.path, relative));
        if (await folder.exists()) return folder;
      }
    }
    final installed = await installer.inspect(spec);
    if (!installed.installed) return null;
    return installer.directoryOf(spec);
  }

  /// Bytes the downloaded copy takes.
  Future<int> installedBytes(LocalComponentSpec spec) =>
      installer.sizeOnDisk(spec);

  /// Whether the machine already provides the component without a download.
  Future<bool> systemAvailable(LocalComponentSpec spec) async {
    if (spec.isRuntime) {
      return await _systemExecutable(spec) != null ||
          await _legacyExecutable(spec) != null;
    }
    for (final name in spec.requiredFiles) {
      if (await _systemOrLegacyFile(spec, name) != null) return true;
    }
    for (final probe in spec.systemPaths) {
      if (await Directory(_expand(probe)).exists()) return true;
    }
    for (final base in _legacyRoots) {
      for (final relative in spec.legacyDirectories) {
        if (await Directory(path.join(base.path, relative)).exists()) {
          return true;
        }
      }
    }
    return false;
  }

  Future<File?> _systemOrLegacyFile(
    LocalComponentSpec spec,
    String name,
  ) async {
    for (final relative in spec.legacyFiles) {
      if (path.basename(relative) != name) continue;
      for (final base in _legacyRoots) {
        final file = File(path.join(base.path, relative));
        if (await file.exists()) return file;
      }
    }
    for (final probe in spec.systemPaths) {
      final file = File(path.join(_expand(probe), name));
      if (await file.exists()) return file;
    }
    return null;
  }

  Future<File?> _systemExecutable(LocalComponentSpec spec) async {
    final name = spec.executable;
    if (name == null) return null;
    final names = spec.systemNames.isEmpty ? [name] : spec.systemNames;
    for (final folder in _systemFolders) {
      for (final candidate in names) {
        final file = File(path.join(folder, candidate));
        if (await isRunnable(file)) return file;
      }
    }
    for (final probe in spec.systemPaths) {
      final expanded = _expand(probe);
      final file = File(expanded);
      if (await isRunnable(file)) return file;
      final folder = Directory(expanded);
      if (await folder.exists()) {
        for (final candidate in names) {
          final found = File(path.join(folder.path, candidate));
          if (await isRunnable(found)) return found;
        }
      }
    }
    return null;
  }

  Future<File?> _legacyExecutable(LocalComponentSpec spec) async {
    final name = spec.executable;
    if (name == null) return null;
    final names = spec.systemNames.isEmpty ? [name] : spec.systemNames;
    for (final base in _legacyRoots) {
      for (final relative in spec.legacyDirectories) {
        final folder = Directory(path.join(base.path, relative));
        for (final candidate in names) {
          final found = File(path.join(folder.path, candidate));
          if (await isRunnable(found)) return found;
        }
      }
    }
    return null;
  }

  List<Directory> get _legacyRoots => [supportDirectory, ?executableDirectory];

  List<String> get _systemFolders {
    final home = environment['HOME'] ?? '';
    return <String>{
      ...(environment['PATH'] ?? '').split(':').where((f) => f.isNotEmpty),
      if (home.isNotEmpty) '$home/.local/bin',
      if (home.isNotEmpty) '$home/bin',
    }.toList();
  }

  String _expand(String probe) {
    if (!probe.startsWith('~')) return probe;
    final home = environment['HOME'] ?? '';
    return path.join(home, probe.substring(1));
  }

  Future<File?> _findInComponent(
    LocalComponentSpec spec,
    String name,
  ) async {
    final root = installer.directoryOf(spec);
    if (!await root.exists()) return null;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File && path.basename(entity.path) == name) return entity;
    }
    return null;
  }

  /// Whether the file is there and the machine may run it.
  static Future<bool> isRunnable(File file) async {
    try {
      if (!await file.exists()) return false;
      final stat = await file.stat();
      return stat.mode & 0x49 != 0;
    } on FileSystemException {
      return false;
    }
  }
}
