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
  ///
  /// The transfer is a background job: the caller may keep playing the track
  /// from the network while it runs, and it may ignore the returned future.
  /// Asking for a track whose transfer is still running joins that transfer
  /// instead of fetching the same bytes a second time, and the progress of
  /// the running transfer is reported to the new caller as well.
  Future<String> download(
    Song song, {
    void Function(double progress)? onProgress,
  });

  /// Stops the transfer of [song] when one is still running.
  ///
  /// The copy of a cancelled transfer is not written, so the track has to be
  /// fetched again when it is played. A track without a running transfer is
  /// left alone.
  void cancel(Song song);

  /// Releases the network client.
  void dispose();
}
