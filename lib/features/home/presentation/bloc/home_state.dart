import 'package:equatable/equatable.dart';
import 'package:tune/domain/entities/song.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Song> recentlyPlayedSongs;
  final List<Song> recommendedSongs;

  const HomeLoaded({
    required this.recentlyPlayedSongs,
    required this.recommendedSongs,
  });

  HomeLoaded copyWith({
    List<Song>? recentlyPlayedSongs,
    List<Song>? recommendedSongs,
  }) {
    return HomeLoaded(
      recentlyPlayedSongs: recentlyPlayedSongs ?? this.recentlyPlayedSongs,
      recommendedSongs: recommendedSongs ?? this.recommendedSongs,
    );
  }

  @override
  List<Object?> get props => [recentlyPlayedSongs, recommendedSongs];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}