import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as path;
import 'package:tune/domain/entities/song.dart';

/// 音乐库服务
/// 负责管理本地音乐库，包括扫描、分类、排序等功能
class MusicLibraryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// 获取所有本地歌曲
  Future<List<Song>> getAllSongs() async {
    try {
      // 检查权限
      final permissionStatus = await _audioQuery.permissionsStatus();
      if (!permissionStatus) {
        final hasPermission = await _audioQuery.permissionsRequest();
        if (!hasPermission) {
          return [];
        }
      }

      // 查询本地歌曲，获取完整的元数据
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final List<Song> songList = [];

      for (var i = 0; i < songs.length; i++) {
        final song = songs[i];

        // 直接使用本地数据源的专辑艺术Uri
        String? albumArtUri;
        if (song.albumId != null) {
          try {
            final artwork = await _audioQuery.queryArtwork(
              song.albumId!,
              ArtworkType.ALBUM,
              format: ArtworkFormat.JPEG,
              size: 200,
            );

            // 处理不同类型的专辑艺术数据
            if (artwork != null) {
              if (artwork is Uint8List) {
                // 将Uint8List转换为文件路径
                final tempDir = Directory.systemTemp;
                final tempFile = File(path.join(tempDir.path, 'album_art_${song.id}.jpg'));
                await tempFile.writeAsBytes(artwork);
                albumArtUri = tempFile.path;
              } else {
                albumArtUri = artwork.toString();
              }
            }
          } catch (e) {
            // 如果无法获取专辑艺术，保持为null
            albumArtUri = null;
          }
        }

        songList.add(
          Song(
            id: song.id,
            title: song.title ?? 'Unknown Title',
            artist: song.artist ?? 'Unknown Artist',
            album: song.album ?? 'Unknown Album',
            genre: song.genre ?? 'Unknown Genre',
            duration: song.duration ?? 0,
            uri: song.uri ?? '',
            albumArtUri: albumArtUri,
            dateAdded: song.dateAdded ?? DateTime.now().millisecondsSinceEpoch,
            isFavorite: false,
          ),
        );
      }

      return songList;
    } catch (e) {
      // 如果出现错误，返回空列表
      return [];
    }
  }

  /// 搜索本地歌曲
  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) {
      return await getAllSongs();
    }

    try {
      // 搜索本地歌曲
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
        // 移除不支持的参数
      );

      // 手动过滤结果
      final filteredSongs = songs.where((song) {
        final title = song.title.toLowerCase();
        final artist = song.artist?.toLowerCase() ?? '';
        final album = song.album?.toLowerCase() ?? '';
        final lowerQuery = query.toLowerCase();
        return title.contains(lowerQuery) ||
               artist.contains(lowerQuery) ||
               album.contains(lowerQuery);
      }).toList();

      final List<Song> songList = [];

      for (var i = 0; i < filteredSongs.length; i++) {
        final song = filteredSongs[i];

        // 获取专辑艺术
        String? albumArtUri;
        if (song.albumId != null) {
          try {
            final artwork = await _audioQuery.queryArtwork(
              song.albumId!,
              ArtworkType.ALBUM,
              format: ArtworkFormat.JPEG,
              size: 200,
            );
            // 将Uint8List转换为文件路径
            if (artwork != null) {
              if (artwork is Uint8List) {
                // 创建临时文件保存专辑艺术
                final tempDir = Directory.systemTemp;
                final tempFile = File(path.join(tempDir.path, 'album_art_${song.id}_search.jpg'));
                await tempFile.writeAsBytes(artwork);
                albumArtUri = tempFile.path;
              } else {
                albumArtUri = artwork.toString();
              }
            }
          } catch (e) {
            // 如果无法获取专辑艺术，保持为null
            albumArtUri = null;
          }
        }

        songList.add(
          Song(
            id: song.id,
            title: song.title ?? 'Unknown Title',
            artist: song.artist ?? 'Unknown Artist',
            album: song.album ?? 'Unknown Album',
            genre: song.genre ?? 'Unknown Genre',
            duration: song.duration ?? 0,
            uri: song.uri ?? '',
            albumArtUri: albumArtUri,
            dateAdded: song.dateAdded ?? DateTime.now().millisecondsSinceEpoch,
            isFavorite: false,
          ),
        );
      }

      return songList;
    } catch (e) {
      // 如果出现错误，返回空列表
      return [];
    }
  }

  /// 按艺术家分组获取歌曲
  Future<Map<String, List<Song>>> getSongsByArtist() async {
    final songs = await getAllSongs();
    final Map<String, List<Song>> songsByArtist = {};

    for (final song in songs) {
      final artist = song.artist ?? '';
      if (songsByArtist.containsKey(artist)) {
        songsByArtist[artist]!.add(song);
      } else {
        songsByArtist[artist] = [song];
      }
    }

    return songsByArtist;
  }

  /// 按专辑分组获取歌曲
  Future<Map<String, List<Song>>> getSongsByAlbum() async {
    final songs = await getAllSongs();
    final Map<String, List<Song>> songsByAlbum = {};

    for (final song in songs) {
      final album = song.album ?? '';
      if (songsByAlbum.containsKey(album)) {
        songsByAlbum[album]!.add(song);
      } else {
        songsByAlbum[album] = [song];
      }
    }

    return songsByAlbum;
  }

  /// 按流派分组获取歌曲
  Future<Map<String, List<Song>>> getSongsByGenre() async {
    final songs = await getAllSongs();
    final Map<String, List<Song>> songsByGenre = {};

    for (final song in songs) {
      final genre = song.genre ?? '';
      if (songsByGenre.containsKey(genre)) {
        songsByGenre[genre]!.add(song);
      } else {
        songsByGenre[genre] = [song];
      }
    }

    return songsByGenre;
  }

  /// 按添加日期排序（最新添加在前）
  Future<List<Song>> getRecentlyAddedSongs({int limit = 50}) async {
    final songs = await getAllSongs();
    songs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return songs.take(limit).toList();
  }

  /// 按播放次数排序（如果记录了播放次数）
  Future<List<Song>> getMostPlayedSongs({int limit = 50}) async {
    // 注意：实际实现中需要从数据库获取播放次数信息
    final songs = await getAllSongs();
    // 这里只是示例，实际应根据播放次数排序
    return songs.take(limit).toList();
  }

  /// 按最近播放排序
  Future<List<Song>> getRecentlyPlayedSongs({int limit = 50}) async {
    // 注意：实际实现中需要从数据库获取最近播放信息
    final songs = await getAllSongs();
    // 这里只是示例，实际应根据最近播放时间排序
    return songs.take(limit).toList();
  }

  /// 获取艺术家列表
  Future<List<String>> getArtists() async {
    final songs = await getAllSongs();
    final artists = <String>{};
    for (final song in songs) {
      if ((song.artist ?? '').isNotEmpty) {
        artists.add(song.artist!);
      }
    }
    return artists.toList()..sort();
  }

  /// 获取专辑列表
  Future<List<String>> getAlbums() async {
    final songs = await getAllSongs();
    final albums = <String>{};
    for (final song in songs) {
      if ((song.album ?? '').isNotEmpty) {
        albums.add(song.album!);
      }
    }
    return albums.toList()..sort();
  }

  /// 获取流派列表
  Future<List<String>> getGenres() async {
    final songs = await getAllSongs();
    final genres = <String>{};
    for (final song in songs) {
      if ((song.genre ?? '').isNotEmpty) {
        genres.add(song.genre!);
      }
    }
    return genres.toList()..sort();
  }

  /// 获取收藏歌曲
  Future<List<Song>> getFavoriteSongs() async {
    // 注意：实际实现中需要从数据库获取收藏信息
    final songs = await getAllSongs();
    // 这里只是示例，实际应根据收藏状态筛选
    return songs.where((song) => song.isFavorite).toList();
  }

  /// 切换歌曲收藏状态
  Future<void> toggleFavorite(int songId) async {
    // 注意：实际实现中需要更新数据库中的收藏状态
    // 这里只是示例
  }

  /// 按时长排序（从短到长）
  Future<List<Song>> getSongsSortedByDuration({bool ascending = true}) async {
    final songs = await getAllSongs();
    songs.sort((a, b) => ascending
        ? a.duration.compareTo(b.duration)
        : b.duration.compareTo(a.duration));
    return songs;
  }

  /// 获取指定艺术家的歌曲
  Future<List<Song>> getSongsByArtistName(String artistName) async {
    final songs = await getAllSongs();
    return songs.where((song) => (song.artist ?? '') == artistName).toList();
  }

  /// 获取指定专辑的歌曲
  Future<List<Song>> getSongsByAlbumName(String albumName) async {
    final songs = await getAllSongs();
    return songs.where((song) => (song.album ?? '') == albumName).toList();
  }

  /// 获取指定流派的歌曲
  Future<List<Song>> getSongsByGenreName(String genreName) async {
    final songs = await getAllSongs();
    return songs.where((song) => (song.genre ?? '') == genreName).toList();
  }

  /// 获取歌曲总数
  Future<int> getTotalSongCount() async {
    final songs = await getAllSongs();
    return songs.length;
  }

  /// 获取所有歌曲的总时长
  Future<int> getTotalDuration() async {
    final songs = await getAllSongs();
    // 修复类型错误
    int totalDuration = 0;
    for (final song in songs) {
      totalDuration += song.duration;
    }
    return totalDuration;
  }
}
