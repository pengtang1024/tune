import 'package:tune/domain/entities/song.dart';

/// 音乐远程数据源
abstract class MusicRemoteDataSource {
  /// 获取在线歌曲
  Future<List<Song>> getOnlineSongs();

  /// 根据ID获取在线歌曲
  Future<Song> getOnlineSongById(int id);

  /// 搜索在线歌曲
  Future<List<Song>> searchOnlineSongs(String query);
}