import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int duration;
  final String uri;
  final String? albumArtUri;
  final int dateAdded;
  final bool isFavorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.duration,
    required this.uri,
    this.albumArtUri,
    required this.dateAdded,
    this.isFavorite = false,
  });

  Song copyWith({
    required int id,
    required String title,
    required String artist,
    required String album,
    required String genre,
    required int duration,
    required String uri,
    String? albumArtUri,
    required int dateAdded,
    required bool isFavorite,
  }) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      duration: duration,
      uri: uri,
      albumArtUri: albumArtUri,
      dateAdded: dateAdded,
      isFavorite: isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        genre,
        duration,
        uri,
        albumArtUri,
        dateAdded,
        isFavorite,
      ];
}
