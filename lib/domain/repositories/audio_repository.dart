import 'package:tune/domain/entities/song.dart';

abstract class AudioRepository {
  Future<List<Song>> getAllSongs();
  Future<void> playSong(Song song);
  Future<List<Song>> searchSongs(String query);
  Future<void> toggleFavorite(Song song);
  Future<List<Song>> getFavoriteSongs();
}