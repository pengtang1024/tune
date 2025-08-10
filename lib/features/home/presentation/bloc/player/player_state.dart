import 'package:equatable/equatable.dart';
import 'package:tune/domain/entities/song.dart';

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

  const PlayerPlaying({
    required this.song,
    required this.position,
    required this.duration,
    required this.volume,
  });

  PlayerPlaying copyWith({
    Song? song,
    Duration? position,
    Duration? duration,
    double? volume,
  }) {
    return PlayerPlaying(
      song: song ?? this.song,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object?> get props => [song, position, duration, volume];
}

class PlayerPaused extends PlayerState {
  final Song song;
  final Duration position;
  final Duration duration;
  final double volume;

  const PlayerPaused({
    required this.song,
    required this.position,
    required this.duration,
    required this.volume,
  });

  PlayerPaused copyWith({
    Song? song,
    Duration? position,
    Duration? duration,
    double? volume,
  }) {
    return PlayerPaused(
      song: song ?? this.song,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object?> get props => [song, position, duration, volume];
}

class PlayerStopped extends PlayerState {}

class PlayerBuffering extends PlayerState {
  final Song song;
  final Duration position;
  final Duration duration;
  final double volume;

  const PlayerBuffering({
    required this.song,
    required this.position,
    required this.duration,
    required this.volume,
  });

  @override
  List<Object?> get props => [song, position, duration, volume];
}

class PlayerError extends PlayerState {
  final String message;

  const PlayerError({required this.message});

  @override
  List<Object?> get props => [message];
}