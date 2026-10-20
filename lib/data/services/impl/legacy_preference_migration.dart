import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/utils/logger.dart';

/// Moves the preferences of the previous store into the current one.
///
/// The previous store was one shared document that every write rewrote from
/// an in-memory snapshot. The current store keeps one file per preference, so
/// the preferences the old document still holds are copied over once, and an
/// upgrade keeps what the user set.
class LegacyPreferenceMigration {
  const LegacyPreferenceMigration._();

  /// Copies the preferences of the previous store into [target].
  ///
  /// A preference that [target] already holds is left alone, so the
  /// migration never overwrites something the user changed after the upgrade.
  static Future<void> migrateInto(PersistenceService target) async {
    final SharedPreferences legacy;
    try {
      legacy = await SharedPreferences.getInstance();
    } catch (error) {
      // The previous store is not there on every platform. Without it there
      // is nothing to move, and that is not a failure.
      Log.info('没有旧偏好可迁移: $error');
      return;
    }

    for (final key in legacy.getKeys()) {
      if (target.containsKey(key)) continue;
      await _copy(legacy, target, key);
    }
  }

  static Future<void> _copy(
    SharedPreferences legacy,
    PersistenceService target,
    String key,
  ) async {
    final value = legacy.get(key);
    switch (value) {
      case final String v:
        await target.setString(key, v);
      case final int v:
        await target.setInt(key, v);
      case final double v:
        await target.setDouble(key, v);
      case final bool v:
        await target.setBool(key, v);
      case final List<Object?> v:
        await target.setStringList(key, v.cast<String>());
    }
  }
}
