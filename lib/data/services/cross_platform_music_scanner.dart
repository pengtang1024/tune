import 'dart:io' show Platform, Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:tune/data/services/music_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// 跨平台音乐扫描服务接口
abstract class CrossPlatformMusicScanner {
  /// 扫描音乐文件
  Future<List<Song>> scanMusic();

  /// 在指定目录中扫描音乐文件
  Future<List<Song>> scanMusicInDirectory(String directoryPath);

  /// 扫描多个目录中的音乐文件
  Future<List<Song>> scanMusicInDirectories(List<String> directoryPaths);
}

/// 跨平台音乐扫描服务实现
class CrossPlatformMusicScannerImpl implements CrossPlatformMusicScanner {
  final MusicService _musicService;

  CrossPlatformMusicScannerImpl(this._musicService);

  @override
  Future<List<Song>> scanMusic() async {
    Log.info('CrossPlatformMusicScanner: Starting cross-platform music scan');

    // 检查平台类型
    if (kIsWeb) {
      // Web平台 - 使用文件选择器
      Log.info('CrossPlatformMusicScanner: Running on Web platform');
      return await _scanWithFilePicker();
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台 - 使用原生音乐查询
      Log.info('CrossPlatformMusicScanner: Running on mobile platform');
      try {
        return await _musicService.getAllSongs();
      } catch (e) {
        Log.info('CrossPlatformMusicScanner: Failed to use native scanner, falling back to file picker: $e');
        return await _scanWithFilePicker();
      }
    } else {
      // 桌面平台 - 使用文件选择器
      Log.info('CrossPlatformMusicScanner: Running on desktop platform');
      return await _scanWithFilePicker();
    }
  }

  @override
  Future<List<Song>> scanMusicInDirectory(String directoryPath) async {
    Log.info('CrossPlatformMusicScanner: Scanning directory: $directoryPath');
    return await _scanDirectory(directoryPath);
  }

  @override
  Future<List<Song>> scanMusicInDirectories(List<String> directoryPaths) async {
    Log.info('CrossPlatformMusicScanner: Scanning ${directoryPaths.length} directories');
    final allSongs = <Song>[];

    for (final path in directoryPaths) {
      try {
        final songs = await _scanDirectory(path);
        allSongs.addAll(songs);
      } catch (e) {
        Log.info('CrossPlatformMusicScanner: Failed to scan directory $path: $e');
      }
    }

    return allSongs;
  }

  /// 使用文件选择器扫描音乐
  Future<List<Song>> _scanWithFilePicker() async {
    try {
      Log.info('CrossPlatformMusicScanner: Opening file picker for directory selection');
      final result = await FilePicker.platform.getDirectoryPath();

      if (result == null) {
        Log.info('CrossPlatformMusicScanner: No directory selected');
        return [];
      }

      Log.info('CrossPlatformMusicScanner: Selected directory: $result');
      return await _scanDirectory(result);
    } catch (e) {
      Log.info('CrossPlatformMusicScanner: Failed to pick directory: $e');
      return [];
    }
  }

  /// 扫描指定目录中的音乐文件
  Future<List<Song>> _scanDirectory(String directoryPath) async {
    Log.info('CrossPlatformMusicScanner: Scanning directory: $directoryPath');

    final songs = <Song>[];
    final audioExtensions = {'.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.wma'};

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        Log.info('CrossPlatformMusicScanner: Directory does not exist: $directoryPath');
        return songs;
      }

      // 递归遍历目录
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final file = entity;
          final path = file.path;
          final extension = _getFileExtension(path).toLowerCase();

          // 检查是否为音频文件
          if (audioExtensions.contains(extension)) {
            try {
              Log.info('CrossPlatformMusicScanner: Found audio file: $path');
              final song = await _createSongFromFile(file);
              songs.add(song);
            } catch (e) {
              Log.info('CrossPlatformMusicScanner: Failed to process file $path: $e');
            }
          }
        }
      }

      Log.info('CrossPlatformMusicScanner: Found ${songs.length} songs in directory: $directoryPath');
      return songs;
    } catch (e) {
      Log.info('CrossPlatformMusicScanner: Failed to scan directory $directoryPath: $e');
      return songs;
    }
  }

  /// 从文件创建歌曲对象
  Future<Song> _createSongFromFile(File file) async {
    final path = file.path;
    final fileName = _getFileNameWithoutExtension(path);
    final stat = await file.stat();

    // 默认值
    var title = fileName;
    var artist = '未知艺术家';
    var album = '未知专辑';
    var duration = 0;

    try {
      // 尝试读取音频元数据
      final metadata = readMetadata(file);

      // 提取元数据
      if (metadata.title != null && metadata.title!.isNotEmpty) {
        title = metadata.title!;
      }

      if (metadata.artist != null && metadata.artist!.isNotEmpty) {
        artist = metadata.artist!;
      }

      if (metadata.album != null && metadata.album!.isNotEmpty) {
        album = metadata.album!;
      }

      if (metadata.duration != null) {
        duration = metadata.duration!.inMilliseconds;
      }
    } catch (e) {
      Log.info('CrossPlatformMusicScanner: Failed to read metadata for $path: $e');
    }

    // 创建歌曲对象
    return Song({
      'id': path.hashCode, // 使用路径的哈希值作为ID
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'uri': path,
      'dateAdded': stat.changed.millisecondsSinceEpoch,
    });
  }

  /// 获取文件扩展名
  String _getFileExtension(String filePath) {
    try {
      return filePath.substring(filePath.lastIndexOf('.'));
    } catch (e) {
      return '';
    }
  }

  /// 获取不带扩展名的文件名
  String _getFileNameWithoutExtension(String filePath) {
    try {
      final fileName = filePath.split(Platform.pathSeparator).last;
      final dotIndex = fileName.lastIndexOf('.');
      return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    } catch (e) {
      return '未知歌曲';
    }
  }
}
