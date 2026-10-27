// Platform dependent library storage.
//
// A build with a file system keeps the library in SQLite inside the
// application support folder. The web build is no longer a target: it keeps
// no library at all.
export 'library_storage_stub.dart'
    if (dart.library.io) 'library_storage_io.dart';
