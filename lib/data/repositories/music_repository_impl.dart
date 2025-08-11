import 'package:tune/data/datasources/local/music_local_datasource.dart';
import 'package:tune/data/datasources/remote/music_remote_datasource.dart';
import 'package:tune/domain/entities/playlist.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/repositories/music_repository.dart';

/// 音乐仓库实现
class MusicRepositoryImpl implements MusicRepository {
  /// 本地数据源
  final MusicLocalDataSource localDataSource;

  /// 远程数据源
  final MusicRemoteDataSource remoteDataSource;

  /// 构造函数
  MusicRepositoryImpl(this.localDataSource, this.remoteDataSource);

  @override
  Future<List<Song>> getAllSongs() async {
    // 首先尝试获取本地歌曲
    final localSongs = await localDataSource.getAllSongs();

    // 然后获取在线歌曲
    final onlineSongs = await remoteDataSource.getOnlineSongs();

    // 合并本地和在线歌曲
    final allSongs = [...localSongs, ...onlineSongs];

    // 转换为实体并返回
    return allSongs;
  }

  @override
  Future<Song?> getSongById(int id) async {
    // 尝试从本地获取
    try {
      final localSong = await localDataSource.getSongById(id);
      return localSong;
    } catch (e) {
      // 如果本地没有，则从远程获取
      try {
        final remoteSong = await remoteDataSource.getOnlineSongById(id);
        return remoteSong;
      } catch (e) {
        return null;
      }
    }
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    // 搜索本地歌曲
    final localSongs = await localDataSource.searchSongs(query);

    // 搜索在线歌曲
    final onlineSongs = await remoteDataSource.searchOnlineSongs(query);

    // 合并结果
    final allSongs = [...localSongs, ...onlineSongs];

    // 去重
    final uniqueSongs = <int, Song>{};
    for (final song in allSongs) {
      uniqueSongs[song.id] = song;
    }

    return uniqueSongs.values.toList();
  }

  @override
  Future<void> toggleFavorite(Song song) async {
    // 切换收藏状态
    await localDataSource.toggleFavorite(song);
  }

  @override
  Future<List<Song>> getFavoriteSongs() async {
    // 获取收藏歌曲
    return await localDataSource.getFavoriteSongs();
  }

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    // 获取所有播放列表
    return await localDataSource.getAllPlaylists();
  }

  @override
  Future<Playlist?> getPlaylistById(int id) async {
    // 根据ID获取播放列表
    return await localDataSource.getPlaylistById(id);
  }

  @override
  Future<Playlist> createPlaylist(String name, String? description) async {
    // 创建播放列表
    return await localDataSource.createPlaylist(name, description);
  }

  @override
  Future<void> addSongToPlaylist(Playlist playlist, Song song) async {
    // 向播放列表添加歌曲
    await localDataSource.addSongToPlaylist(playlist, song);
  }

  @override
  Future<void> removeSongFromPlaylist(Playlist playlist, Song song) async {
    // 从播放列表移除歌曲
    await localDataSource.removeSongFromPlaylist(playlist, song);
  }
}
