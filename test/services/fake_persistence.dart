import 'package:tune/data/services/persistence_service.dart';

/// In-memory persistence used by service/controller tests.
class FakePersistenceService implements PersistenceService {
  final Map<String, Object?> values = {};

  @override
  Future<void> init() async {}

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setInt(String key, int value) async {
    values[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  Future<bool> setBool(String key, bool value) async {
    values[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<bool> setDouble(String key, double value) async {
    values[key] = value;
    return true;
  }

  @override
  double? getDouble(String key) => values[key] as double?;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    values[key] = List<String>.of(value);
    return true;
  }

  @override
  List<String>? getStringList(String key) {
    final value = values[key];
    return value is List<String> ? List<String>.of(value) : null;
  }

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Set<String> getKeys() => values.keys.toSet();
}
