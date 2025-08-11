import 'package:tune/domain/entities/playlist.dart';
import 'package:tune/domain/entities/song.dart';

/// 音乐本地数据源
abstract class MusicLocalDataSource {
  /// 获取所有本地歌曲
  Future<List<Song>> getAllSongs();

  /// 根据ID获取本地歌曲
  Future<Song> getSongById(int id);

  /// 搜索本地歌曲
  Future<List<Song>> searchSongs(String query);

  /// 切换歌曲收藏状态
  Future<void> toggleFavorite(Song song);

  /// 获取收藏歌曲
  Future<List<Song>> getFavoriteSongs();

  /// 获取所有播放列表
  Future<List<Playlist>> getAllPlaylists();

  /// 根据ID获取播放列表
  Future<Playlist> getPlaylistById(int id);

  /// 创建播放列表
  Future<Playlist> createPlaylist(String name, String? description);

  /// 向播放列表添加歌曲
  Future<void> addSongToPlaylist(Playlist playlist, Song song);

  /// 从播放列表移除歌曲
  Future<void> removeSongFromPlaylist(Playlist playlist, Song song);
}
