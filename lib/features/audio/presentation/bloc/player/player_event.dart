abstract class PlayerEvent {}

class PlaySongEvent extends PlayerEvent {
  final int songId;
  
  PlaySongEvent(this.songId);

  @override
  String toString() {
    return 'PlaySongEvent{songId: $songId}';
  }
}

class TogglePlayPauseEvent extends PlayerEvent {
  @override
  String toString() {
    return 'TogglePlayPauseEvent{}';
  }
}

class StopEvent extends PlayerEvent {
  @override
  String toString() {
    return 'StopEvent{}';
  }
}

class SkipToNextEvent extends PlayerEvent {
  @override
  String toString() {
    return 'SkipToNextEvent{}';
  }
}

class SkipToPreviousEvent extends PlayerEvent {
  @override
  String toString() {
    return 'SkipToPreviousEvent{}';
  }
}

class SeekToEvent extends PlayerEvent {
  final Duration position;
  
  SeekToEvent(this.position);

  @override
  String toString() {
    return 'SeekToEvent{position: $position}';
  }
}

class SetVolumeEvent extends PlayerEvent {
  final double volume;
  
  SetVolumeEvent(this.volume);

  @override
  String toString() {
    return 'SetVolumeEvent{volume: $volume}';
  }
}

class UpdateProgressEvent extends PlayerEvent {
  final Duration position;
  
  UpdateProgressEvent(this.position);

  @override
  String toString() {
    return 'UpdateProgressEvent{position: $position}';
  }
}

class SetPlayModeEvent extends PlayerEvent {
  final PlayMode playMode;
  
  SetPlayModeEvent(this.playMode);

  @override
  String toString() {
    return 'SetPlayModeEvent{playMode: $playMode}';
  }
}

class SetPlaybackSpeedEvent extends PlayerEvent {
  final double speed;
  
  SetPlaybackSpeedEvent(this.speed);

  @override
  String toString() {
    return 'SetPlaybackSpeedEvent{speed: $speed}';
  }
}

class PlayErrorEvent extends PlayerEvent {
  final String message;
  
  PlayErrorEvent(this.message);

  @override
  String toString() {
    return 'PlayErrorEvent{message: $message}';
  }
}

enum PlayMode {
  repeatAll,
  repeatOne,
  shuffle,
}