import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/data/services/persistence_service.dart';

/// SharedPreferences持久化服务实现
class SharedPreferencesService implements PersistenceService {
  SharedPreferences? _prefs;
  SharedPreferencesService(){
    init();
  }

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  @override
  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString(key);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(key, value);
  }

  @override
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs!.getInt(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs!.getBool(key);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _ensureInitialized();
    return await _prefs!.setDouble(key, value);
  }

  @override
  double? getDouble(String key) {
    _ensureInitialized();
    return _prefs!.getDouble(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    return await _prefs!.setStringList(key, value);
  }

  @override
  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  @override
  bool containsKey(String key) {
    _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  @override
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs!.remove(key);
  }

  @override
  Future<bool> clear() async {
    _ensureInitialized();
    return await _prefs!.clear();
  }

  @override
  Set<String> getKeys() {
    _ensureInitialized();
    return _prefs!.getKeys();
  }

  /// 确保服务已初始化
  void _ensureInitialized() {
    if (_prefs == null) {
      throw StateError('SharedPreferencesService not initialized. '
          'Please call init() before using any methods.');
    }
  }
}