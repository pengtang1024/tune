import 'package:tune/domain/models/song.dart';

/// Stores remote tracks on disk so they can be replayed without a network.
///
/// The service owns the layout of the store. The playback controller only asks
/// whether a track was already fetched and where the fetched file lives, so
/// the caching policy stays in one place.
abstract class SongDownloadService {
  /// Whether the platform can keep a copy of a track on disk.
  ///
  /// The web build has no file system; the player then streams the track
  /// directly instead of asking for a cached file.
  bool get isSupported;

  /// Returns the stored copy of [song] when it was fetched before.
  Future<String?> storedFileFor(Song song);

  /// Fetches [song] into the local store and returns the file path.
  ///
  /// [onProgress] reports a value between 0 and 1 while the transfer runs.
  /// The call throws when the track cannot be fetched.
  Future<String> download(
    Song song, {
    void Function(double progress)? onProgress,
  });

  /// Releases the network client.
  void dispose();
}
