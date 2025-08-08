import 'package:on_audio_query/on_audio_query.dart' as on_audio;
import 'package:tune/data/models/song_model.dart';

abstract class AudioLocalDataSource {
  Future<List<SongModel>> getAllSongs();
  Future<List<SongModel>> searchSongs(String query);
  Future<void> toggleFavorite(int songId);
  Future<List<SongModel>> getFavoriteSongs();
}

class AudioLocalDataSourceImpl implements AudioLocalDataSource {
  final on_audio.OnAudioQuery onAudioQuery;

  AudioLocalDataSourceImpl(this.onAudioQuery);

  @override
  Future<List<SongModel>> getAllSongs() async {
    final songs = await onAudioQuery.querySongs(
      sortType: on_audio.SongSortType.DATE_ADDED,
      orderType: on_audio.OrderType.DESC_OR_GREATER,
      uriType: on_audio.UriType.EXTERNAL,
    );
    
    return songs.map((song) => SongModel.fromAudioQuerySong(song)).toList();
  }

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    final songs = await onAudioQuery.querySongs(
      // 移除了不存在的sortBy参数
      sortType: on_audio.SongSortType.TITLE,
      orderType: on_audio.OrderType.ASC_OR_SMALLER,
      uriType: on_audio.UriType.EXTERNAL,
    );
    
    return songs.map((song) => SongModel.fromAudioQuerySong(song)).toList();
  }

  @override
  Future<void> toggleFavorite(int songId) async {
    // 实现收藏逻辑
    // 在实际应用中，可能需要使用数据库存储收藏状态
  }

  @override
  Future<List<SongModel>> getFavoriteSongs() async {
    // 返回收藏的歌曲列表
    return [];
  }
}