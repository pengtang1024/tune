import 'package:equatable/equatable.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_event.dart';

abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerPlaying extends PlayerState {
  final Song song;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final PlayMode playMode;

  const PlayerPlaying({
    required this.song,
    required this.position,
    required this.duration,
    required this.volume,
    this.speed = 1.0,
    this.playMode = PlayMode.repeatAll,
  });

  PlayerPlaying copyWith({
    Song? song,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    PlayMode? playMode,
  }) {
    return PlayerPlaying(
      song: song ?? this.song,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      playMode: playMode ?? this.playMode,
    );
  }

  @override
  List<Object?> get props => [song, position, duration, volume, speed, playMode];

  @override
  String toString() {
    return 'PlayerPlaying{song: ${song.title}, position: $position, duration: $duration, volume: $volume, speed: $speed, playMode: $playMode}';
  }
}

class PlayerPaused extends PlayerState {
  final Song song;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final PlayMode playMode;

  const PlayerPaused({
    required this.song,
    required this.position,
    required this.duration,
    required this.volume,
    this.speed = 1.0,
    this.playMode = PlayMode.repeatAll,
  });

  PlayerPaused copyWith({
    Song? song,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    PlayMode? playMode,
  }) {
    return PlayerPaused(
      song: song ?? this.song,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      playMode: playMode ?? this.playMode,
    );
  }

  @override
  List<Object?> get props => [song, position, duration, volume, speed, playMode];

  @override
  String toString() {
    return 'PlayerPaused{song: ${song.title}, position: $position, duration: $duration, volume: $volume, speed: $speed, playMode: $playMode}';
  }
}

class PlayerStopped extends PlayerState {
  @override
  String toString() {
    return 'PlayerStopped{}';
  }
}

class PlayerBuffering extends PlayerState {
  final Song song;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final PlayMode playMode;

  const PlayerBuffering({
    required this.song,
    required this.position,
    required this.duration,
    required this.volume,
    this.speed = 1.0,
    this.playMode = PlayMode.repeatAll,
  });

  @override
  List<Object?> get props => [song, position, duration, volume, speed, playMode];

  @override
  String toString() {
    return 'PlayerBuffering{song: ${song.title}, position: $position, duration: $duration, volume: $volume, speed: $speed, playMode: $playMode}';
  }
}

class PlayerError extends PlayerState {
  final String message;

  const PlayerError({required this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() {
    return 'PlayerError{message: $message}';
  }
}