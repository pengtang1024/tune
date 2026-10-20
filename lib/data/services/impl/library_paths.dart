// Platform dependent library paths.
//
// Desktop and mobile builds keep the files of the app in the music library
// of the machine. The web build has no file system, so it uses the stub,
// which keeps nothing on disk.
export 'library_paths_stub.dart' if (dart.library.io) 'library_paths_io.dart';
