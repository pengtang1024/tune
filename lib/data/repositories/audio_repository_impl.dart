import 'package:tune/data/datasources/audio_local_data_source.dart';
import 'package:tune/data/datasources/audio_remote_data_source.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/repositories/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  final AudioLocalDataSource localDataSource;
  final AudioRemoteDataSource remoteDataSource;

  AudioRepositoryImpl(this.localDataSource, this.remoteDataSource);

  @override
  Future<List<Song>> getAllSongs() async {
    // 首先尝试获取本地歌曲
    final localSongs = await localDataSource.getAllSongs();
    
    // 然后获取在线歌曲
    final onlineSongs = await remoteDataSource.getOnlineSongs();
    
    // 合并本地和在线歌曲
    final allSongs = [...localSongs, ...onlineSongs];
    
    // 转换为实体并返回
    return allSongs.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> playSong(Song song) async {
    // 播放歌曲的逻辑将在AudioService中实现
    // 这里可以添加日志记录或其他业务逻辑
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    // 搜索本地歌曲
    final localSongs = await localDataSource.searchSongs(query);
    
    // 搜索在线歌曲
    final onlineSongs = await remoteDataSource.searchOnlineSongs(query);
    
    // 合并结果
    final allSongs = [...localSongs, ...onlineSongs];
    
    // 转换为实体并返回
    return allSongs.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> toggleFavorite(Song song) async {
    // 切换收藏状态
    await localDataSource.toggleFavorite(song.id);
  }

  @override
  Future<List<Song>> getFavoriteSongs() async {
    // 获取收藏的歌曲
    final favoriteSongs = await localDataSource.getFavoriteSongs();
    return favoriteSongs.map((model) => model.toEntity()).toList();
  }
}