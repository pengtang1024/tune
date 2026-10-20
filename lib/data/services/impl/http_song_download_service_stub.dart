import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/artwork/artwork_cache.dart';
import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/domain/models/song.dart';

/// The download store of a build that has no file system.
SongDownloadService createSongDownloadService({
  required LibraryPaths paths,
  required ArtworkCache artwork,
}) => HttpSongDownloadService();

/// Download store for platforms without a file system.
///
/// The web build cannot keep a copy of a track on disk. The service therefore
/// reports that caching is unavailable and refuses to fetch, so the player
/// falls back to streaming the track.
class HttpSongDownloadService implements SongDownloadService {
  @override
  bool get isSupported => false;

  @override
  Future<String?> storedFileFor(Song song) async => null;

  @override
  Future<void> markCopiesOf(Iterable<Song> songs) async {}

  @override
  Future<String> download(
    Song song, {
    void Function(double progress)? onProgress,
  }) {
    throw UnsupportedError(AppStrings.instance.downloadUnsupportedPlatform);
  }

  @override
  void cancel(Song song) {}

  @override
  void dispose() {}
}
