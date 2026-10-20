import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/utils/logger.dart';

/// Fetches the copy of the track the queue plays next.
///
/// The prefetch never decides the playback: when it fails, the next track is
/// streamed instead of replayed from the store. Only one track is prefetched,
/// so the network never carries more than the copy of the playing track and
/// the copy of the next one.
class TrackPrefetcher {
  TrackPrefetcher(this._downloads);

  final SongDownloadService _downloads;

  /// The track whose copy is being fetched ahead of the playback.
  Song? _prefetched;

  /// Fetches the copy of the track after [index] in [queue].
  ///
  /// The progress of the prefetch is not reported: the badge belongs to the
  /// track that plays.
  Future<void> prefetch({
    required int index,
    required List<Song> queue,
    required PlayMode playMode,
  }) async {
    if (!_downloads.isSupported) return;
    final next = _nextToPrefetch(
      index: index,
      queue: queue,
      playMode: playMode,
    );
    if (next == null) return;
    if (!next.isRemote || next.isLiveStream) return;

    _prefetched = next;
    try {
      final stored = await _downloads.storedFileFor(next);
      if (stored != null) {
        _forget(next);
        return;
      }
      await _downloads.download(next);
      _forget(next);
    } catch (error, stackTrace) {
      Log.error('预取音源失败: $error\n$stackTrace');
    }
  }

  /// Stops the prefetch of a track the queue left behind.
  ///
  /// The transfer of the track that plays now or next keeps running: the
  /// prefetch and the copy of the playing track are the same transfer then.
  void release({
    required Song keep,
    required int index,
    required List<Song> queue,
    required PlayMode playMode,
  }) {
    final prefetched = _prefetched;
    if (prefetched == null) return;
    if (prefetched.uri == keep.uri) {
      _prefetched = null;
      return;
    }
    final wanted = _nextToPrefetch(
      index: index,
      queue: queue,
      playMode: playMode,
    );
    if (wanted != null && wanted.uri == prefetched.uri) return;
    _prefetched = null;
    _downloads.cancel(prefetched);
  }

  /// Stops the prefetch that is running.
  void stop() {
    final prefetched = _prefetched;
    if (prefetched == null) return;
    _prefetched = null;
    _downloads.cancel(prefetched);
  }

  /// Stops the prefetch of [song] when it is the one that runs.
  void stopIf(Song song) {
    if (_prefetched?.uri != song.uri) return;
    stop();
  }

  /// The track whose copy is worth fetching while [index] plays.
  ///
  /// The queue hands over to the following track, so its copy is the one that
  /// makes the handover instant. A shuffled queue hands over to a random
  /// track, but the following one is a track the user queued, so its copy is
  /// never wasted. A repeated track needs no copy: the track that plays again
  /// is the one that is already being cached.
  Song? _nextToPrefetch({
    required int index,
    required List<Song> queue,
    required PlayMode playMode,
  }) {
    if (queue.length < 2) return null;
    if (playMode == PlayMode.repeatOne) return null;
    return queue[(index + 1) % queue.length];
  }

  /// Forgets the prefetch of [song] when it is the one that runs.
  void _forget(Song song) {
    if (_prefetched?.uri == song.uri) {
      _prefetched = null;
    }
  }
}
