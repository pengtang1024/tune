import 'package:tune/domain/models/song.dart';

abstract class MusicService {
  Future<List<Song>> getAllSongs();
  Future<List<Song>> searchSongs(String query);
}