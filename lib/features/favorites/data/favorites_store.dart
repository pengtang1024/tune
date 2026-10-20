import 'package:tune/data/services/persistence_service.dart';

/// Keeps the tracks the user marked with a heart.
///
/// The library is the index of the music on the disk, and it is written
/// again on every scan. The favorites are a note of the user about that
/// music, so they live in their own place: a heart survives a rescan and a
/// restart of the app.
class FavoritesStore {
  FavoritesStore(this._persistence);

  /// The key the addresses of the favorites are kept under.
  static const String key = 'favorite_tracks';

  final PersistenceService _persistence;

  /// The tracks that are marked, read from the store.
  Set<String> read() {
    final ids = _persistence.getStringList(key) ?? const <String>[];
    return Set<String>.unmodifiable(ids.where((id) => id.isNotEmpty));
  }

  /// Writes the tracks that are marked into the store.
  ///
  /// The addresses are written in a fixed order, so the file of the store
  /// only changes when the set of the favorites does.
  Future<void> write(Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _persistence.setStringList(key, sorted);
  }
}
