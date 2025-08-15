import 'package:tune/data/services/music_service.dart';
import 'package:tune/domain/models/song.dart';

class MusicRepository {
  final MusicService musicService;

  MusicRepository({required this.musicService});

  Future<List<Song>> getAllSongs() async {
    return await musicService.getAllSongs();
  }

  Future<List<Song>> searchSongs(String query) async {
    return await musicService.searchSongs(query);
  }
}