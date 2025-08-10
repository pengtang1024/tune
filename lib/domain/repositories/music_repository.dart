import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/entities/playlist.dart';

/// 音乐仓库接口
///
/// 定义获取歌曲、歌单的契约
abstract class MusicRepository {
  /// 获取所有歌曲
  Future<List<Song>> getAllSongs();

  /// 根据ID获取歌曲
  Future<Song?> getSongById(int id);

  /// 搜索歌曲
  Future<List<Song>> searchSongs(String query);

  /// 切换收藏状态
  Future<void> toggleFavorite(Song song);

  /// 获取收藏歌曲
  Future<List<Song>> getFavoriteSongs();

  /// 获取所有播放列表
  Future<List<Playlist>> getAllPlaylists();

  /// 根据ID获取播放列表
  Future<Playlist?> getPlaylistById(int id);

  /// 创建播放列表
  Future<Playlist> createPlaylist(String name, String? description);

  /// 向播放列表添加歌曲
  Future<void> addSongToPlaylist(Playlist playlist, Song song);

  /// 从播放列表移除歌曲
  Future<void> removeSongFromPlaylist(Playlist playlist, Song song);
}