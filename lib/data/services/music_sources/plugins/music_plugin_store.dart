import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/music_source.dart';

/// Stores imported MusicFree plugin scripts under the app support directory.
class MusicPluginStore {
  static const _directoryName = 'music_plugins';

  final Directory? _baseDirectory;

  MusicPluginStore({Directory? baseDirectory}) : _baseDirectory = baseDirectory;

  Future<Directory> _directory() async {
    final base = _baseDirectory ?? await getApplicationSupportDirectory();
    final directory = Directory(path.join(base.path, _directoryName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File?> fileFor(MusicSourceConfig config) async {
    final name = config.pluginFile;
    if (name == null || name.isEmpty) return null;

    // Never allow a persisted setting to escape the plugin directory.
    final safeName = path.basename(name);
    if (safeName != name || !safeName.endsWith('.js')) return null;

    final directory = await _directory();
    return File(path.join(directory.path, safeName));
  }

  Future<String> read(MusicSourceConfig config) async {
    final file = await fileFor(config);
    if (file == null || !await file.exists()) {
      throw StateError(AppStrings.instance.pluginFileMissing);
    }
    return file.readAsString();
  }

  Future<String> write(String id, String script) async {
    final directory = await _directory();
    final fileName = '$id.js';
    final file = File(path.join(directory.path, fileName));
    await file.writeAsString(script, flush: true);
    return fileName;
  }

  /// Replaces the script of an already installed plugin.
  ///
  /// The file keeps its name, so the source id and the songs that were
  /// scanned with the old script stay valid.
  Future<void> writeScript(MusicSourceConfig config, String script) async {
    final file = await fileFor(config);
    if (file == null) {
      throw StateError(AppStrings.instance.pluginFileMissing);
    }
    await file.writeAsString(script, flush: true);
  }

  Future<void> delete(MusicSourceConfig config) async {
    final file = await fileFor(config);
    if (file == null) return;
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<String>> listFileNames() async {
    final directory = await _directory();
    final entries = await directory.list().toList();
    return [
      for (final entry in entries)
        if (entry is File && entry.path.endsWith('.js'))
          path.basename(entry.path),
    ];
  }
}
