import 'dart:convert';

import 'package:tune/data/services/persistence_service.dart';

/// Remembers the tracks whose playback failed, without removing them.
///
/// A track that fails may be a dead link or a network that went away for a
/// moment; the library keeps it and the row carries a mark instead. The mark
/// is cleared as soon as the track plays again.
class DeadSongStore {
  DeadSongStore(this._persistence);

  /// The key the failed tracks are kept under.
  static const String key = 'dead_songs_v1';

  final PersistenceService _persistence;

  /// The tracks whose last playback failed.
  Set<String> read() {
    final raw = _persistence.getString(key);
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return {
        for (final item in decoded)
          if (item is String && item.isNotEmpty) item,
      };
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> write(Set<String> uris) async {
    final sorted = uris.toList(growable: false)..sort();
    await _persistence.setString(key, jsonEncode(sorted));
  }
}
