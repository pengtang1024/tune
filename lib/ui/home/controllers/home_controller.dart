import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

class HomeController {
  final MusicRepository _musicRepository;

  HomeController({required MusicRepository musicRepository})
      : _musicRepository = musicRepository;

  Future<List<Song>> getAllSongs() async {
    try {
      Log.info('HomeController: Getting all songs');
      final songs = await _musicRepository.getAllSongs();
      Log.info('HomeController: Found ${songs.length} songs');
      return songs;
    } catch (e) {
      Log.info('HomeController: Error getting all songs: $e');
      return [];
    }
  }
}