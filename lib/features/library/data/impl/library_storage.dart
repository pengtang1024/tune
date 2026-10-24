// Platform dependent library storage.
//
// Desktop and mobile builds keep the library in a file in the application
// support folder. The web build has no file system, so it keeps the same
// document in the browser store.
export 'library_storage_stub.dart'
    if (dart.library.io) 'library_storage_io.dart';
