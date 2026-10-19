/// Playback order semantics.
///
/// - [sequential]: play through the queue and wrap at the end.
/// - [repeatOne]: automatically replay the current track when it finishes.
/// - [shuffle]: pick a random different track when advancing.
enum PlayMode { sequential, repeatOne, shuffle }
