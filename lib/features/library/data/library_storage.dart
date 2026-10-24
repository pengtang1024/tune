import 'package:tune/domain/models/song.dart';

/// The library of the app, as the songs it holds.
///
/// The storage owns the document, and how it is kept follows the platform: a
/// build with a file system writes a file in the application support folder,
/// the web build keeps the document in the browser store.
abstract class LibraryStorage {
  /// The songs of the library, empty when the library holds none.
  Future<List<Song>> load();

  /// Writes the songs into the library.
  Future<void> save(List<Song> songs);

  /// Removes the library.
  Future<void> clear();
}
