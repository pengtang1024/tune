import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/persistence_service.dart';

/// The folder the reader picked through the system directory picker (SAF).
///
/// The choice is kept in the same preference as the folder of a desktop
/// (`library_folder`), because both answer one question: where the local
/// tracks come from. A `content://` value is a tree the system hands back
/// with a persistable permission; a path is the file system of a desktop.
///
/// The store only reads. The settings controller remains the one writer of
/// the preference (`docs/android.md` §5).
class SafTreeStore {
  const SafTreeStore(this._persistence);

  final PersistenceService _persistence;

  /// The tree the reader picked, when the preference holds one.
  String? get treeUri {
    final value = _persistence.getString(LibraryPaths.rootKey)?.trim();
    return isTreeUri(value) ? value : null;
  }

  /// Whether [value] is a SAF tree instead of a file system path.
  static bool isTreeUri(String? value) =>
      value != null && value.startsWith('content://');
}
