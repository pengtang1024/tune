// 移除on_audio_query导入
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tune/data/models/song_model.dart';

abstract class AudioLocalDataSource {
  Future<List<SongModel>> getAllSongs();
  Future<List<SongModel>> searchSongs(String query);
  Future<void> toggleFavorite(int songId);
  Future<List<SongModel>> getFavoriteSongs();
}

class AudioLocalDataSourceImpl implements AudioLocalDataSource {
  // 移除onAudioQuery依赖

  AudioLocalDataSourceImpl(); // 移除构造函数参数

  @override
  Future<List<SongModel>> getAllSongs() async {
    // 实现基本的本地音乐文件查询功能
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync(recursive: true);

      final List<SongModel> songs = [];
      int id = 1;

      for (final FileSystemEntity file in files) {
        if (file is File && _isAudioFile(file.path)) {
          final String fileName = file.uri.pathSegments.last;
          final String title = fileName.replaceAll(RegExp(r'\.[^.]*$'), ''); // 移除扩展名
          final FileStat stat = await file.stat();

          songs.add(
            SongModel(
              id: id++,
              title: title,
              artist: 'Unknown Artist',
              album: 'Unknown Album',
              genre: 'Unknown Genre',
              duration: 0, // 无法获取实际时长
              uri: file.path,
              albumArtUri: null,
              dateAdded: stat.changed.millisecondsSinceEpoch,
              isFavorite: false,
            ),
          );
        }
      }

      return songs;
    } catch (e) {
      // 如果出现错误，返回空列表
      return [];
    }
  }

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    final List<SongModel> allSongs = await getAllSongs();
    if (query.isEmpty) {
      return allSongs;
    }

    return allSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase()) ||
          song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Future<void> toggleFavorite(int songId) async {
    // 实现收藏逻辑
    // 在实际应用中，应该将收藏状态保存到本地存储
  }

  @override
  Future<List<SongModel>> getFavoriteSongs() async {
    // 实现获取收藏歌曲逻辑
    return [];
  }

  /// 检查文件是否为音频文件
  bool _isAudioFile(String path) {
    final List<String> audioExtensions = [
      '.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.wma'
    ];

    for (final String extension in audioExtensions) {
      if (path.toLowerCase().endsWith(extension)) {
        return true;
      }
    }

    return false;
  }
}
