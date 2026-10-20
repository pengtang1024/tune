import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/impl/legacy_preference_migration.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/utils/logger.dart';

/// The preference store of a build that has a file system.
PersistenceService createPersistenceService() => FilePersistenceService();

/// Keeps every preference in its own file under the application support folder.
///
/// The store this replaces kept all preferences in one document and rewrote
/// that document from an in-memory snapshot on every write. Two processes of
/// the app therefore wrote over each other's keys: the one that wrote last
/// dropped every key the other one had saved. One file per preference removes
/// the conflict, because a write only touches the file of the preference it
/// names.
class FilePersistenceService implements PersistenceService {
  FilePersistenceService({Future<Directory> Function()? directory})
    : _directory = directory;

  /// The folder inside the application support folder that holds the files.
  static const String folderName = 'settings';

  final Future<Directory> Function()? _directory;

  /// The preferences read at startup, served without touching the disk again.
  final Map<String, _Preference> _preferences = {};

  Directory? _root;

  @override
  Future<void> init() async {
    _root = await _resolveRoot();
    await _readAll();
    await LegacyPreferenceMigration.migrateInto(this);
  }

  @override
  Future<bool> setString(String key, String value) =>
      _write(key, 'string', value);

  @override
  Future<bool> setInt(String key, int value) => _write(key, 'int', value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _write(key, 'double', value);

  @override
  Future<bool> setBool(String key, bool value) => _write(key, 'bool', value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _write(key, 'stringList', value);

  @override
  String? getString(String key) => _valueOf<String>(key, 'string');

  @override
  int? getInt(String key) => _valueOf<int>(key, 'int');

  @override
  double? getDouble(String key) => _valueOf<double>(key, 'double');

  @override
  bool? getBool(String key) => _valueOf<bool>(key, 'bool');

  @override
  List<String>? getStringList(String key) {
    final value = _valueOf<List<dynamic>>(key, 'stringList');
    return value?.cast<String>().toList(growable: false);
  }

  @override
  bool containsKey(String key) => _preferences.containsKey(key);

  @override
  Future<bool> remove(String key) async {
    final file = File(path.join(_root!.path, _fileName(key)));
    if (await file.exists()) {
      await file.delete();
    }
    _preferences.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    final entries = await _root!.list().toList();
    for (final entry in entries) {
      if (entry is File) await entry.delete();
    }
    _preferences.clear();
    return true;
  }

  @override
  Set<String> getKeys() => _preferences.keys.toSet();

  /// The folder that holds the files of every preference.
  Future<Directory> _resolveRoot() async {
    final base = await (_directory?.call() ?? getApplicationSupportDirectory());
    final root = Directory(path.join(base.path, folderName));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  /// Reads every preference that is already on disk.
  Future<void> _readAll() async {
    final entries = await _root!.list().toList();
    for (final entry in entries) {
      if (entry is! File) continue;
      final key = _keyOf(entry.path);
      if (key == null) continue;
      final preference = await _readFile(entry);
      if (preference != null) _preferences[key] = preference;
    }
  }

  /// Writes one preference and keeps it in memory for the readers.
  Future<bool> _write(String key, String type, Object value) async {
    final file = File(path.join(_root!.path, _fileName(key)));
    final payload = jsonEncode({'type': type, 'value': value});
    try {
      await _writeThroughTemporaryFile(file, payload);
    } catch (error, stackTrace) {
      Log.error('写入偏好失败: $key\n$stackTrace');
      return false;
    }
    _preferences[key] = _Preference(type, value);
    return true;
  }

  /// Writes through a temporary file, so a reader never sees half a file.
  ///
  /// The temporary file carries the process id, so two processes that write
  /// the same preference at the same time do not fight over one temporary
  /// file.
  Future<void> _writeThroughTemporaryFile(File file, String content) async {
    final temporary = File('${file.path}.$pid.tmp');
    await temporary.writeAsString(content, flush: true);
    await temporary.rename(file.path);
  }

  Future<_Preference?> _readFile(File file) async {
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final type = decoded['type'];
      final value = decoded['value'];
      if (type is! String || value == null) return null;

      return _Preference(type, value);
    } catch (error, stackTrace) {
      Log.error('读取偏好失败: ${file.path}\n$stackTrace');
      return null;
    }
  }

  T? _valueOf<T>(String key, String type) {
    final preference = _preferences[key];
    if (preference == null || preference.type != type) return null;
    // The value goes into a local first, because the analyzer only knows
    // the type of a field after the check when the field never changes.
    final value = preference.value;
    return value is T ? value as T : null;
  }

  /// The file name of one preference.
  ///
  /// The key is encoded, so that every key fits a file name on every
  /// platform, and so that the key can be read back exactly.
  static String _fileName(String key) =>
      '${_encoded(key)}.json';

  /// The key a file name belongs to, or null when the name is not ours.
  static String? _keyOf(String filePath) {
    final name = path.basename(filePath);
    if (!name.endsWith('.json')) return null;
    final encoded = name.substring(0, name.length - '.json'.length);
    try {
      return utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
    } on FormatException {
      return null;
    }
  }

  static String _encoded(String key) =>
      base64Url.encode(utf8.encode(key)).replaceAll('=', '');
}

/// One preference as it is kept on disk: what it is, and what it holds.
class _Preference {
  const _Preference(this.type, this.value);

  final String type;
  final Object value;
}
