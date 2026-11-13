import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/utils/logger.dart';

/// Keeps the keys of the translation vendors out of the settings file.
///
/// The settings document is plain preferences and may be shown, copied or
/// synced; a key is not. The keys live in their own file in the application
/// support folder, written only by this store, and the owner is the only one
/// allowed to read it where the platform can say so.
class TranslationKeyStore {
  TranslationKeyStore({Future<Directory> Function()? directory})
    : _directory = directory;

  /// The name of the file in the application support folder.
  static const String fileName = 'translation_keys.json';

  final Future<Directory> Function()? _directory;

  Map<String, String> _keys = const {};
  Future<void>? _loading;

  /// The keys by the id of the vendor. Empty until [init] read the file.
  Map<String, String> get keys => _keys;

  /// Reads the file that is already there. A missing or broken file means no
  /// key at all; the reader pastes one again rather than the app refusing to
  /// start.
  Future<void> init() {
    return _loading ??= _load();
  }

  /// Writes the keys that carry a value, one file, replaced as a whole.
  Future<void> write(Map<String, String> keys) async {
    final cleaned = <String, String>{};
    for (final entry in keys.entries) {
      final id = entry.key.trim();
      final key = entry.value.trim();
      if (id.isEmpty || key.isEmpty) continue;
      cleaned[id] = key;
    }

    final base = await _supportDirectory();
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    final file = File(path.join(base.path, fileName));
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(cleaned), flush: true);
    await temporary.rename(file.path);
    await _restrict(file);
    _keys = Map<String, String>.unmodifiable(cleaned);
  }

  Future<void> _load() async {
    try {
      final base = await _supportDirectory();
      final file = File(path.join(base.path, fileName));
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final loaded = <String, String>{};
      decoded.forEach((id, key) {
        if (id is String && key is String && key.trim().isNotEmpty) {
          loaded[id] = key.trim();
        }
      });
      _keys = Map<String, String>.unmodifiable(loaded);
    } catch (error, stackTrace) {
      Log.error('读取翻译密钥失败: $error\n$stackTrace');
    }
  }

  Future<Directory> _supportDirectory() {
    final resolve = _directory;
    return resolve != null ? resolve() : getApplicationSupportDirectory();
  }

  /// Hides the file from everyone but its owner, where the platform allows it.
  Future<void> _restrict(File file) async {
    if (!Platform.isLinux && !Platform.isMacOS) return;
    try {
      await Process.run('chmod', ['600', file.path]);
    } catch (_) {
      // The file still works without the narrower mode.
    }
  }
}
