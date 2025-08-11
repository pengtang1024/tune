import 'package:tune/domain/entities/song.dart';

abstract class HomeLocalDataSource {
  /// 获取最近播放的歌曲
  Future<List<Song>> getRecentlyPlayedSongs();

  /// 获取推荐歌曲
  Future<List<Song>> getRecommendedSongs();

  /// 保存最近播放的歌曲
  Future<void> saveRecentlyPlayedSong(Song song);
}