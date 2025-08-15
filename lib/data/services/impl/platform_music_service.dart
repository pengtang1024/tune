import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:logger/logger.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:tune/data/services/music_service.dart';
import 'package:tune/domain/models/song.dart' as tune;

class PlatformMusicService implements MusicService {
  OnAudioQuery? _audioQuery;
  final Logger _logger = Logger();

  PlatformMusicService() {
    // 只在支持的平台上初始化 on_audio_query
    if (!_isSupportedPlatform()) {
      _audioQuery = null;
    } else {
      try {
        _audioQuery = OnAudioQuery();
      } catch (e) {
        // 处理插件初始化失败的情况
        _logger.e('Failed to initialize OnAudioQuery: $e');
        _audioQuery = null;
      }
    }
  }

  bool _isSupportedPlatform() {
    // on_audio_query 支持 Android 和 iOS
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || 
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<List<tune.Song>> getAllSongs() async {
    // 如果在不支持的平台上运行，返回空列表
    if (_audioQuery == null) {
      _logger.i('Audio query not supported on this platform: $defaultTargetPlatform');
      return [];
    }

    try {
      // 请求权限
      bool permissionStatus;
      try {
        permissionStatus = await _audioQuery!.permissionsStatus();
      } catch (e) {
        // 在某些平台上可能不支持权限检查
        _logger.w('Permission check failed, assuming granted: $e');
        permissionStatus = true;
      }

      if (!permissionStatus) {
        bool status;
        try {
          status = await _audioQuery!.permissionsRequest();
        } catch (e) {
          _logger.e('Permission request failed: $e');
          throw Exception('Permission denied to access music library');
        }
        if (!status) {
          throw Exception('Permission denied to access music library');
        }
      }

      // 获取所有歌曲
      final songs = await _audioQuery!.querySongs(
        sortType: SongSortType.DISPLAY_NAME,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      // 转换为我们的Song模型
      return songs.map((song) => tune.Song(song.getMap)).toList();
    } catch (e) {
      _logger.e('Failed to fetch songs: $e');
      throw Exception('Failed to fetch songs: $e');
    }
  }

  @override
  Future<List<tune.Song>> searchSongs(String query) async {
    // 如果在不支持的平台上运行，返回空列表
    if (_audioQuery == null) {
      _logger.i('Audio query not supported on this platform: $defaultTargetPlatform');
      return [];
    }

    try {
      final songs = await _audioQuery!.querySongs(
        sortType: SongSortType.DISPLAY_NAME,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        path: query, // 使用path参数进行搜索
      );

      return songs.map((song) => tune.Song(song.getMap)).toList();
    } catch (e) {
      _logger.e('Failed to search songs: $e');
      throw Exception('Failed to search songs: $e');
    }
  }
}