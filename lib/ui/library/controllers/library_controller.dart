import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

class LibraryController {
  final MusicRepository _musicRepository;

  LibraryController({required MusicRepository musicRepository})
      : _musicRepository = musicRepository;

  /// 获取所有歌曲
  Future<List<Song>> getAllSongs() async {
    try {
      Log.info('LibraryController: Getting all songs');
      final songs = await _musicRepository.getAllSongs();
      Log.info('LibraryController: Found ${songs.length} songs');
      return songs;
    } catch (e) {
      Log.info('LibraryController: Error getting all songs: $e');
      // 返回空列表而不是抛出错误，确保UI可以正常显示
      return [];
    }
  }
}