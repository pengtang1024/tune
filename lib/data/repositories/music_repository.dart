import 'package:tune/data/services/music_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

class MusicRepository {
  final MusicService musicService;

  MusicRepository({required this.musicService});

  Future<List<Song>> getAllSongs() async {
    try {
      Log.info('MusicRepository: Getting all songs');
      final songs = await musicService.getAllSongs();
      Log.info('MusicRepository: Found ${songs.length} songs');
      return songs;
    } catch (e) {
      Log.info('MusicRepository: Error getting all songs: $e');
      // 返回空列表而不是抛出错误，确保UI可以正常显示
      return [];
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    try {
      Log.info('MusicRepository: Searching songs with query: $query');
      final songs = await musicService.searchSongs(query);
      Log.info('MusicRepository: Found ${songs.length} songs in search');
      return songs;
    } catch (e) {
      Log.info('MusicRepository: Error searching songs: $e');
      // 返回空列表而不是抛出错误，确保UI可以正常显示
      return [];
    }
  }
}