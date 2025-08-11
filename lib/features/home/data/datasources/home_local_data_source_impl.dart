import 'package:tune/domain/entities/song.dart';
import 'package:tune/features/home/data/datasources/home_local_data_source.dart';

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  @override
  Future<List<Song>> getRecentlyPlayedSongs() async {
    // TODO: 实现获取最近播放歌曲的逻辑
    // 这里应该从本地数据库或shared preferences中获取数据
    return [];
  }

  @override
  Future<List<Song>> getRecommendedSongs() async {
    // TODO: 实现获取推荐歌曲的逻辑
    // 这里应该基于用户喜好或其他算法来推荐歌曲
    return [];
  }

  @override
  Future<void> saveRecentlyPlayedSong(Song song) async {
    // TODO: 实现保存最近播放歌曲的逻辑
    // 这里应该将歌曲信息保存到本地数据库或shared preferences中
  }
}