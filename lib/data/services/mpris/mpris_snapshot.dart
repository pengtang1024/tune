/// The track the system media controls show.
///
/// The fields are the ones the media player specification names; the player
/// fills them from the track that is playing right now.
class MprisTrack {
  const MprisTrack({
    required this.id,
    required this.title,
    this.artists = const [],
    this.album = '',
    this.artUrl,
    this.url,
    this.length = Duration.zero,
  });

  /// Identifier of the track inside the player namespace.
  ///
  /// The specification wants an object path, so the value may only contain
  /// the characters a path element allows.
  final String id;

  /// Title of the track.
  final String title;

  /// The people who performed the track.
  final List<String> artists;

  /// Album the track belongs to.
  final String album;

  /// Address of the cover image.
  final String? artUrl;

  /// Address of the audio itself.
  final String? url;

  /// Length of the track.
  final Duration length;

  @override
  bool operator ==(Object other) {
    return other is MprisTrack &&
        other.id == id &&
        other.title == title &&
        other.artists.length == artists.length &&
        other.artists.every(artists.contains) &&
        other.album == album &&
        other.artUrl == artUrl &&
        other.url == url &&
        other.length == length;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    Object.hashAll(artists),
    album,
    artUrl,
    url,
    length,
  );
}

/// How the player is doing right now, in the words of the specification.
enum MprisPlaybackStatus { playing, paused, stopped }

/// How the queue repeats, in the words of the specification.
enum MprisLoopStatus { none, track, playlist }

/// Everything the system needs to know about the player at one moment.
///
/// The snapshot is the only thing the media controls read, so the player
/// publishes a new one whenever something worth showing changed.
class MprisSnapshot {
  const MprisSnapshot({
    this.status = MprisPlaybackStatus.stopped,
    this.track,
    this.position = Duration.zero,
    this.volume = 1,
    this.rate = 1,
    this.shuffle = false,
    this.loopStatus = MprisLoopStatus.none,
    this.canPlay = false,
    this.canPause = false,
    this.canGoNext = false,
    this.canGoPrevious = false,
    this.canSeek = false,
  });

  /// The state of the playback.
  final MprisPlaybackStatus status;

  /// The track that is playing, if there is one.
  final MprisTrack? track;

  /// How far the playback got.
  final Duration position;

  /// The volume, from 0 to 1.
  final double volume;

  /// The speed of the playback.
  final double rate;

  /// Whether the queue is played in random order.
  final bool shuffle;

  /// How the queue repeats.
  final MprisLoopStatus loopStatus;

  /// Whether there is something to play.
  final bool canPlay;

  /// Whether the playback can be paused.
  final bool canPause;

  /// Whether another track can be started.
  final bool canGoNext;

  /// Whether the previous track can be started.
  final bool canGoPrevious;

  /// Whether the position inside the track can be changed.
  final bool canSeek;
}
