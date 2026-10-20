// Platform dependent artwork cache.
//
// Desktop and mobile builds keep every cover on disk, so a restart does not
// fetch the same covers again. The web build has no file system, so it uses
// the stub, which fetches the cover every time.
export 'artwork_cache_stub.dart' if (dart.library.io) 'artwork_cache_io.dart';
