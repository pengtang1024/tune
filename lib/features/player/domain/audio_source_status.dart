/// Where the audio of the current track comes from.
///
/// The player never streams straight from the network: a remote track is
/// fetched to disk first and replayed from the local copy afterwards.
enum AudioSourceStatus {
  /// The track always lived on this machine.
  local,

  /// The track is being fetched into the local store right now.
  downloading,

  /// The track was fetched before and is replayed from the local copy.
  cached,

  /// The fetch failed, so the track cannot be played.
  failed,
}
