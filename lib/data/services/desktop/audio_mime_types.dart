/// The audio types Tune can play.
///
/// The list is the single source of truth for the desktop entry, the media
/// controls and the action that makes Tune the default player.
const supportedAudioMimeTypes = <String>[
  'audio/mpeg',
  'audio/mp3',
  'audio/x-wav',
  'audio/wav',
  'audio/wave',
  'audio/x-pn-wav',
  'audio/flac',
  'audio/x-flac',
  'audio/ogg',
  'audio/x-ogg',
  'audio/opus',
  'audio/mp4',
  'audio/x-m4a',
  'audio/aac',
  'audio/x-aac',
];

/// The desktop entry that describes Tune to the system.
const tuneDesktopEntryName = 'cn.iouf.tune.desktop';
