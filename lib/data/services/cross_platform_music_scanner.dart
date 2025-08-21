import 'dart:io' show Platform, Directory, File;
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as audio_meta;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
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

  /// 扫描单个文件
  Future<Song?> scanMusicFile(String filePath);
  
  /// 获取所有歌曲
  Future<List<Song>> getAllSongs();

  /// 搜索歌曲
  Future<List<Song>> searchSongs(String query);
}

/// 跨平台音乐扫描服务实现
class CrossPlatformMusicScannerImpl implements CrossPlatformMusicScanner {
  CrossPlatformMusicScannerImpl();

  @override
  Future<List<Song>> scanMusic() async {
    Log.info('CrossPlatformMusicScanner: Starting cross-platform music scan');

    // 检查平台类型
    if (kIsWeb) {
      // Web平台 - 返回空列表，因为Web平台需要用户手动选择文件
      Log.info('CrossPlatformMusicScanner: Running on Web platform');
      return [];
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台 - 返回空列表（实际项目中应该使用移动平台特定的API）
      Log.info('CrossPlatformMusicScanner: Running on mobile platform');
      return [];
    } else {
      // 桌面平台 - 返回空列表，避免自动弹出文件选择器
      Log.info('CrossPlatformMusicScanner: Running on desktop platform');
      return [];
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

    for (final dirPath in directoryPaths) {
      try {
        final songs = await _scanDirectory(dirPath);
        allSongs.addAll(songs);
      } catch (e) {
        Log.info('CrossPlatformMusicScanner: Failed to scan directory $dirPath: $e');
      }
    }

    return allSongs;
  }

  @override
  Future<Song?> scanMusicFile(String filePath) async {
    Log.info('CrossPlatformMusicScanner: Scanning single file: $filePath');
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await _createSongFromFile(file);
      }
    } catch (e) {
      Log.info('CrossPlatformMusicScanner: Failed to scan file $filePath: $e');
    }
    return null;
  }

  /// 获取所有歌曲
  @override
  Future<List<Song>> getAllSongs() async {
    return await scanMusic();
  }

  /// 搜索歌曲
  @override
  Future<List<Song>> searchSongs(String query) async {
    // 简单实现：返回所有歌曲（实际项目中应该根据查询条件过滤）
    return await scanMusic();
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
      Log.info('CrossPlatformMusicScanner: Failed to scan with file picker: $e');
      return [];
    }
  }

  /// 扫描目录中的音乐文件
  Future<List<Song>> _scanDirectory(String directoryPath) async {
    final songs = <Song>[];
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      Log.info('CrossPlatformMusicScanner: Directory does not exist: $directoryPath');
      return songs;
    }

    try {
      await for (final file in directory.list(recursive: true, followLinks: false)) {
        if (file is File && _isAudioFile(file.path)) {
          try {
            final song = await _createSongFromFile(file);
            if (song != null) {
              songs.add(song);
            }
          } catch (e) {
            Log.info('CrossPlatformMusicScanner: Failed to create song from file ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      Log.info('CrossPlatformMusicScanner: Error scanning directory $directoryPath: $e');
    }

    Log.info('CrossPlatformMusicScanner: Found ${songs.length} songs in directory: $directoryPath');
    return songs;
  }

  /// 检查文件是否为音频文件
  bool _isAudioFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ext == '.mp3' || ext == '.flac' || ext == '.wav' || ext == '.m4a' || ext == '.aac' || ext == '.ogg';
  }

  /// 从文件创建歌曲对象
  Future<Song?> _createSongFromFile(File file) async {
    final filePath = file.path;
    final fileName = path.basenameWithoutExtension(filePath);

    try {
      // 读取音频文件元数据
      final metadata = audio_meta.readMetadata(file);

      // 创建歌曲数据映射
      final songData = <String, dynamic>{
        'id': filePath.hashCode, // 使用文件路径的哈希值作为ID
        'title': metadata.title ?? fileName,
        'artist': metadata.artist ?? 'Unknown Artist',
        'album': metadata.album ?? 'Unknown Album',
        'duration': metadata.duration?.inMilliseconds ?? 0,
        'uri': filePath,
        'dateAdded': DateTime.now().millisecondsSinceEpoch,
        'year': metadata.year,
      };

      return Song(songData);
    } catch (e) {
      Log.info('CrossPlatformMusicScanner: Failed to read metadata for $filePath: $e');
      // 如果无法读取元数据，则创建一个基本的歌曲对象
      final songData = <String, dynamic>{
        'id': filePath.hashCode,
        'title': fileName,
        'artist': 'Unknown Artist',
        'album': 'Unknown Album',
        'duration': 0,
        'uri': filePath,
        'dateAdded': DateTime.now().millisecondsSinceEpoch,
        'year': 0,
      };

      return Song(songData);
    }
  }
}