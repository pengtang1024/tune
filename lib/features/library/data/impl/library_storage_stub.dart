import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/data/library_document.dart';
import 'package:tune/features/library/data/library_storage.dart';
import 'package:tune/utils/logger.dart';

/// The library storage of a build that has no file system.
LibraryStorage createLibraryStorage(PersistenceService persistence) =>
    BrowserLibraryStorage(persistence);

/// Persists the scanned library in the browser store.
///
/// The web build has no file system, so the library lives next to the other
/// data of the app: the preferences of the browser. The document is the same
/// one a build with a file system writes, so both builds read the same songs.
///
/// The library of the browser is what the online sources brought in. It is
/// kept between two visits, so a return to the page shows the same library
/// instead of an empty one.
class BrowserLibraryStorage implements LibraryStorage {
  BrowserLibraryStorage(this._persistence);

  /// The key the library document is kept under.
  static const String key = 'scanned_songs_v1';

  final PersistenceService _persistence;

  @override
  Future<List<Song>> load() async {
    try {
      final raw = _persistence.getString(key);
      if (raw == null || raw.trim().isEmpty) return const [];

      return decodeLibrary(raw);
    } catch (error, stackTrace) {
      Log.error('读取音乐库失败: $error\n$stackTrace');
      return const [];
    }
  }

  @override
  Future<void> save(List<Song> songs) async {
    try {
      await _persistence.setString(key, encodeLibrary(songs));
    } catch (error, stackTrace) {
      // The library is a cache of what the sources brought in. A browser that
      // refuses to store it must not take the player down with it.
      Log.error('保存音乐库失败: $error\n$stackTrace');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _persistence.remove(key);
    } catch (error, stackTrace) {
      Log.error('清空音乐库失败: $error\n$stackTrace');
    }
  }
}
