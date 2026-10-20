/// Where the audio of the current track comes from.
///
/// Playback always comes first: a remote track starts playing straight from
/// the network, and the local copy is fetched in parallel. Only a track that
/// is stored already is read from the disk.
enum AudioSourceStatus {
  /// The track always lived on this machine.
  local,

  /// The audio comes straight from the network and is never stored.
  ///
  /// A live stream never ends and a platform without a file system cannot
  /// keep a copy, so both play the network address directly.
  streaming,

  /// The audio comes from the network while the local copy is fetched.
  ///
  /// The track is already playing; the transfer only fills the store for the
  /// next time the track is played.
  caching,

  /// A local copy exists and the playback reads it.
  cached,

  /// The track could not be played.
  failed,
}
