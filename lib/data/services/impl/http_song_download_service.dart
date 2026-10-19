// Platform dependent download store.
//
// Desktop and mobile builds keep the fetched tracks in the application
// support folder. The web build has no file system, so it uses the stub
// which reports that caching is unavailable and the player streams the
// track directly.
export 'http_song_download_service_stub.dart'
    if (dart.library.io) 'http_song_download_service_io.dart';
