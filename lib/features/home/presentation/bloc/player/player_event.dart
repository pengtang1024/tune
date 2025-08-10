abstract class PlayerEvent {}

class PlaySongEvent extends PlayerEvent {
  final int songId;
  
  PlaySongEvent(this.songId);
}

class TogglePlayPauseEvent extends PlayerEvent {}

class StopEvent extends PlayerEvent {}

class SkipToNextEvent extends PlayerEvent {}

class SkipToPreviousEvent extends PlayerEvent {}

class SeekToEvent extends PlayerEvent {
  final Duration position;
  
  SeekToEvent(this.position);
}

class SetVolumeEvent extends PlayerEvent {
  final double volume;
  
  SetVolumeEvent(this.volume);
}

class UpdateProgressEvent extends PlayerEvent {
  final Duration position;
  
  UpdateProgressEvent(this.position);
}

class SetPlayModeEvent extends PlayerEvent {
  final PlayMode playMode;
  
  SetPlayModeEvent(this.playMode);
}

class SetPlaybackSpeedEvent extends PlayerEvent {
  final double speed;
  
  SetPlaybackSpeedEvent(this.speed);
}

enum PlayMode {
  repeatAll,
  repeatOne,
  shuffle,
}
