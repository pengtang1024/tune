// Platform dependent preference store.
//
// Desktop and mobile builds keep one file per preference in the application
// support folder. The web build has no file system, so it uses the stub,
// which keeps the preferences in the browser.
export 'preference_store_stub.dart'
    if (dart.library.io) 'preference_store_io.dart';
