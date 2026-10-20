import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/playback_source.dart';

/// Decides where the audio of a track comes from.
///
/// Playback comes first: a remote track that is not stored yet plays straight
/// from the network, and its local copy is fetched in the background. Only a
/// track that is stored already is read from the disk.
class AudioSourceResolver {
  AudioSourceResolver(this._downloads);

  final SongDownloadService _downloads;

  /// The source the track has to be played from.
  ///
  /// The answer never waits for a transfer: a track whose copy is missing
  /// plays from the network and reports the copy as the cache target.
  Future<PlaybackSource> sourceFor(Song song) async {
    if (!song.isRemote) {
      return const PlaybackSource(status: AudioSourceStatus.local);
    }

    if (song.isLiveStream || !_downloads.isSupported) {
      // A live stream never ends and a platform without a file system cannot
      // keep a copy, so both play the network address directly.
      return const PlaybackSource(status: AudioSourceStatus.streaming);
    }

    final stored = await _downloads.storedFileFor(song);
    if (stored != null) {
      return PlaybackSource(file: stored, status: AudioSourceStatus.cached);
    }

    // The track plays from the network while the copy is fetched in parallel.
    return PlaybackSource(
      status: AudioSourceStatus.caching,
      cacheTarget: song,
    );
  }
}
