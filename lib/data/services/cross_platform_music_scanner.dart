import 'dart:io' show Platform, Directory, File;
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as audio_meta;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

// 添加debugPrint导入
import 'package:flutter/material.dart' show debugPrint;

/// 跨平台音乐扫描服务接口
abstract class CrossPlatformMusicScanner {
  /// 扫描音乐文件
  Future<List<Song>> scanMusic();

  /// 在指定目录中扫描音乐文件
  Future<List<Song>> scanMusicInDirectory(String directoryPath);

  /// 扫描多个目录中的音乐文件
  Future<List<Song>> scanMusicInDirectories(List<String> directoryPaths);

  /// 扫描多个目录中的音乐文件，并提供进度回调
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
      List<String> directoryPaths, Function(double) onProgress);

  /// 扫描单个文件
  Future<Song?> scanMusicFile(String filePath);

  /// 获取所有歌曲
  Future<List<Song>> getAllSongs();

  /// 搜索歌曲
  Future<List<Song>> searchSongs(String query);

  /// 获取默认音乐路径
  List<String> getDefaultMusicPaths();
  
  /// 扫描自定义路径
  Future<List<Song>> scanCustomPaths(List<String> paths);
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
      // 移动平台 - 使用平台特定的API扫描音乐文件
      Log.info('CrossPlatformMusicScanner: Running on mobile platform');
      try {
        final paths = await _getMobileMusicPaths();
        return await scanMusicInDirectories(paths);
      } catch (e) {
        Log.error('Failed to scan mobile music: $e');
        return [];
      }
    } else {
      // 桌面平台 - 扫描默认音乐目录
      Log.info('CrossPlatformMusicScanner: Running on desktop platform');
      final defaultPaths = getDefaultMusicPaths();
      return await scanMusicInDirectories(defaultPaths);
    }
  }

  @override
  Future<List<Song>> scanMusicInDirectory(String directoryPath) async {
    Log.info('CrossPlatformMusicScanner: Scanning directory: $directoryPath');
    return await _scanDirectory(directoryPath, (progress) {});
  }

  @override
  Future<List<Song>> scanMusicInDirectories(List<String> directoryPaths) async {
    Log.info('CrossPlatformMusicScanner: Scanning ${directoryPaths.length} directories');
    return await scanMusicInDirectoriesWithProgress(directoryPaths, (progress) {});
  }

  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
      List<String> directoryPaths, Function(double) onProgress) async {
    Log.info('CrossPlatformMusicScanner: Scanning ${directoryPaths.length} directories with progress');
    final allSongs = <Song>[];

    for (int i = 0; i < directoryPaths.length; i++) {
      final dirPath = directoryPaths[i];
      try {
        final songs = await _scanDirectory(dirPath, (progress) {
          // 计算整体进度
          final overallProgress = (i + progress) / directoryPaths.length;
          onProgress(overallProgress);
        });
        allSongs.addAll(songs);
      } catch (e) {
        Log.info('CrossPlatformMusicScanner: Failed to scan directory $dirPath: $e');
      }
      // 更新进度
      onProgress((i + 1) / directoryPaths.length);
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
    final allSongs = await scanMusic();
    if (query.isEmpty) {
      return allSongs;
    }

    return allSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
             song.artist.toLowerCase().contains(query.toLowerCase()) ||
             song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// 获取默认音乐路径
  @override
  List<String> getDefaultMusicPaths() {
    final paths = <String>[];

    if (Platform.isWindows) {
      // Windows音乐目录
      final userHome = Platform.environment['USERPROFILE'];
      if (userHome != null) {
        paths.add(path.join(userHome, 'Music'));
      }
    } else if (Platform.isMacOS) {
      // macOS音乐目录
      final userHome = Platform.environment['HOME'];
      if (userHome != null) {
        paths.add(path.join(userHome, 'Music'));
      }
    } else if (Platform.isLinux) {
      // Linux音乐目录
      final userHome = Platform.environment['HOME'];
      if (userHome != null) {
        paths.add(path.join(userHome, 'Music'));
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台音乐目录
      paths.addAll(_getMobileMusicPaths());
    }

    return paths;
  }

  /// 扫描目录中的音乐文件
  Future<List<Song>> _scanDirectory(String directoryPath, Function(double) onProgress) async {
    final songs = <Song>[];
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      Log.info('CrossPlatformMusicScanner: Directory does not exist: $directoryPath');
      return songs;
    }

    try {
      // 先获取所有文件列表以计算进度
      final files = <File>[];
      await for (final file in directory.list(recursive: true, followLinks: false)) {
        if (file is File && _isAudioFile(file.path)) {
          files.add(file);
        }
      }

      Log.info('CrossPlatformMusicScanner: Found ${files.length} audio files in directory: $directoryPath');

      // 处理每个音频文件
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        try {
          final song = await _createSongFromFile(file);
          if (song != null) {
            songs.add(song);
          }
        } catch (e) {
          Log.info('CrossPlatformMusicScanner: Failed to create song from file ${file.path}: $e');
        }
        // 更新进度
        onProgress((i + 1) / files.length);
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

  /// 获取移动平台音乐路径
  List<String> _getMobileMusicPaths() {
    if (Platform.isAndroid) {
      return ['/storage/emulated/0/Music'];
    } else if (Platform.isIOS) {
      return ['/var/mobile/Media/Music'];
    }
    return [];
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
        'data': filePath, // 使用data字段存储文件路径
        'uri': filePath, // 同时保留uri字段以保持兼容性
        'dateAdded': DateTime.now().millisecondsSinceEpoch,
        'year': metadata.year?.year, // 从DateTime中提取年份
        'genre': metadata.genres?.isNotEmpty == true ? metadata.genres!.first : null,
        'bitrate': metadata.bitrate,
        'sampleRate': metadata.sampleRate,
        'trackNumber': metadata.trackNumber,
        'trackTotal': metadata.trackTotal,
        'discNumber': metadata.discNumber,
        'totalDisc': metadata.totalDisc,
        'lyrics': metadata.lyrics,
        'genres': metadata.genres,
        'performers': metadata.performers,
        'language': metadata.language,
        'size': await file.length(),
        'type': 'audio', // 添加类型字段以区分音频和视频
        'isFavorite': false,
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
        'data': filePath,
        'uri': filePath,
        'dateAdded': DateTime.now().millisecondsSinceEpoch,
        'year': 0,
        'size': await file.length(),
        'type': 'audio',
        'isFavorite': false,
      };

      return Song(songData);
    }
  }

  @override
  Future<List<Song>> scanCustomPaths(List<String> paths) async {
    final allSongs = <Song>[];
    
    // 定义支持的音频格式
    final supportedFormats = {'mp3', 'flac', 'wav', 'm4a', 'aac', 'ogg'};
    
    for (final path in paths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await for (final fileEntity in dir.list(recursive: true, followLinks: false)) {
          if (fileEntity is File) {
            final file = fileEntity;
            final extension = file.path.split('.').last.toLowerCase();
            if (supportedFormats.contains(extension)) {
              try {
                final song = await _createSongFromFile(file);
                if (song != null) {
                  allSongs.add(song);
                }
              } catch (e) {
                debugPrint('Error scanning file ${file.path}: $e');
              }
            }
          }
        }
      }
    }
    
    return allSongs;
  }
}