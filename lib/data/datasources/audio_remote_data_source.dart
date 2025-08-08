import 'package:tune/data/models/song_model.dart';

abstract class AudioRemoteDataSource {
  Future<List<SongModel>> getOnlineSongs();
  Future<List<SongModel>> searchOnlineSongs(String query);
}

class AudioRemoteDataSourceImpl implements AudioRemoteDataSource {
  @override
  Future<List<SongModel>> getOnlineSongs() async {
    // 模拟在线歌曲数据
    return [];
  }

  @override
  Future<List<SongModel>> searchOnlineSongs(String query) async {
    // 模拟在线搜索结果
    return [];
  }
}