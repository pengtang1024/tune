import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/data/services/persistence_service.dart';

/// The preference store of a build that has no file system.
PersistenceService createPersistenceService() => BrowserPreferenceService();

/// Keeps the preferences in the browser, for the build without a file system.
///
/// The web build has no application support folder, so the preferences live
/// in the browser store instead. Only one tab of the app is open at a time,
/// so the browser store never has two writers on one document.
class BrowserPreferenceService implements PersistenceService {
  SharedPreferences? _preferences;

  BrowserPreferenceService();

  @override
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  @override
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return await _preferences!.setString(key, value);
  }

  @override
  String? getString(String key) {
    _ensureInitialized();
    return _preferences!.getString(key);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return await _preferences!.setInt(key, value);
  }

  @override
  int? getInt(String key) {
    _ensureInitialized();
    return _preferences!.getInt(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return await _preferences!.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    _ensureInitialized();
    return _preferences!.getBool(key);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _ensureInitialized();
    return await _preferences!.setDouble(key, value);
  }

  @override
  double? getDouble(String key) {
    _ensureInitialized();
    return _preferences!.getDouble(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    return await _preferences!.setStringList(key, value);
  }

  @override
  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _preferences!.getStringList(key);
  }

  @override
  bool containsKey(String key) {
    _ensureInitialized();
    return _preferences!.containsKey(key);
  }

  @override
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _preferences!.remove(key);
  }

  @override
  Future<bool> clear() async {
    _ensureInitialized();
    return await _preferences!.clear();
  }

  @override
  Set<String> getKeys() {
    _ensureInitialized();
    return _preferences!.getKeys();
  }

  /// 确保服务已初始化
  void _ensureInitialized() {
    if (_preferences == null) {
      throw StateError(
        'BrowserPreferenceService not initialized. '
        'Please call init() before using any methods.',
      );
    }
  }
}
