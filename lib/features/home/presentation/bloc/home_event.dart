import 'package:tune/domain/entities/song.dart';

abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}

class SaveRecentlyPlayedSong extends HomeEvent {
  final Song song;

  SaveRecentlyPlayedSong({required this.song});
}