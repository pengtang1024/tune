import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:tune/data/services/music_service.dart';
import 'package:tune/domain/models/song.dart' as tune;
import 'package:tune/utils/logger.dart';

class PlatformMusicService implements MusicService {
  OnAudioQuery? _audioQuery;
  bool _permissionsChecked = false; // 是否已检查权限支持
  bool _permissionsSupported = true; // 默认假设支持权限

  PlatformMusicService() {
    _initializeAudioQuery();
  }

  void _initializeAudioQuery() {
    try {
      _audioQuery = OnAudioQuery();
      // 初始化时标记权限尚未检查
      _permissionsChecked = false;
      _permissionsSupported = true; // 默认假设支持
      Log.info('PlatformMusicService: OnAudioQuery initialized successfully');
    } catch (e) {
      // 处理插件初始化失败的情况
      Log.info('PlatformMusicService: Failed to initialize OnAudioQuery: $e');
      _audioQuery = null;
    }
  }

  /// 检查当前平台是否需要权限检查
  bool _needsPermissionCheck() {
    Log.info('PlatformMusicService: Checking if permission check is needed for platform: $defaultTargetPlatform');
    // 只在Android和iOS平台上需要权限检查
    // Web和其他桌面平台不需要权限检查
    final needsCheck = defaultTargetPlatform == TargetPlatform.android || 
                      defaultTargetPlatform == TargetPlatform.iOS;
    Log.info('PlatformMusicService: Permission check needed: $needsCheck');
    return needsCheck;
  }

  /// 检查权限功能是否可用
  Future<void> _checkPermissionsSupport() async {
    Log.info('PlatformMusicService: Checking permissions support, already checked: $_permissionsChecked');
    // 如果已经检查过权限支持，则直接返回
    if (_permissionsChecked) {
      return;
    }

    // 只在需要权限检查的平台上检查权限支持
    if (!_needsPermissionCheck()) {
      Log.info('PlatformMusicService: Platform does not need permission check, setting permissions supported to false');
      _permissionsSupported = false;
      _permissionsChecked = true;
      return;
    }

    // 在Android和iOS平台上，我们假设权限是支持的
    Log.info('PlatformMusicService: Platform needs permission check, assuming permissions are supported');
    _permissionsSupported = true;
    _permissionsChecked = true;
  }

  /// 尝试检查权限状态
  Future<bool> _checkPermissionStatus() async {
    Log.info('PlatformMusicService: Checking permission status, permissions supported: $_permissionsSupported');
    // 确保已检查权限支持
    await _checkPermissionsSupport();
    
    if (!_permissionsSupported) {
      // 如果权限不受支持，假设已授权
      Log.info('PlatformMusicService: Permissions not supported, assuming granted');
      return true;
    }

    try {
      Log.info('PlatformMusicService: Calling permissionsStatus method');
      final result = await _audioQuery!.permissionsStatus();
      Log.info('PlatformMusicService: Permission status check result: $result');
      return result;
    } catch (e) {
      Log.info('PlatformMusicService: Permission check failed with exception: $e');
      // 检查是否为MissingPluginException
      if (e is MissingPluginException || e.toString().contains('MissingPluginException')) {
        Log.info('PlatformMusicService: MissingPluginException detected, marking permissions as not supported');
        // 标记权限不支持并返回true
        _permissionsSupported = false;
        return true;
      }
      Log.info('PlatformMusicService: Permission check failed, assuming granted: $e');
      return true;
    }
  }

  /// 尝试请求权限
  Future<bool> _requestPermission() async {
    Log.info('PlatformMusicService: Requesting permission, permissions supported: $_permissionsSupported');
    // 确保已检查权限支持
    await _checkPermissionsSupport();
    
    if (!_permissionsSupported) {
      // 如果权限不受支持，假设已授权
      Log.info('PlatformMusicService: Permissions not supported for request, assuming granted');
      return true;
    }

    try {
      Log.info('PlatformMusicService: Calling permissionsRequest method');
      final result = await _audioQuery!.permissionsRequest();
      Log.info('PlatformMusicService: Permission request result: $result');
      return result;
    } catch (e) {
      Log.info('PlatformMusicService: Permission request failed with exception: $e');
      // 检查是否为MissingPluginException
      if (e is MissingPluginException || e.toString().contains('MissingPluginException')) {
        Log.info('PlatformMusicService: MissingPluginException detected in request, marking permissions as not supported');
        // 标记权限不支持并返回true
        _permissionsSupported = false;
        return true;
      }
      Log.info('PlatformMusicService: Permission request failed, assuming granted: $e');
      return true;
    }
  }

  @override
  Future<List<tune.Song>> getAllSongs() async {
    Log.info('PlatformMusicService: getAllSongs called');
    if (_audioQuery == null) {
      Log.info('PlatformMusicService: Audio query is null, returning empty list');
      // 检查是否为Web平台
      if (kIsWeb) {
        throw Exception('Web平台不支持本地音乐扫描功能');
      }
      // 检查是否为桌面平台
      if (defaultTargetPlatform == TargetPlatform.windows || 
          defaultTargetPlatform == TargetPlatform.macOS || 
          defaultTargetPlatform == TargetPlatform.linux) {
        throw Exception('桌面平台不支持本地音乐扫描功能');
      }
      return [];
    }

    try {
      // 检查并请求权限（如果支持）
      Log.info('PlatformMusicService: Checking permissions before fetching songs');
      bool permissionStatus = await _checkPermissionStatus();
      Log.info('PlatformMusicService: Permission status: $permissionStatus');
      
      if (!permissionStatus) {
        Log.info('PlatformMusicService: Requesting permissions');
        bool status = await _requestPermission();
        Log.info('PlatformMusicService: Permission request status: $status');
        if (!status) {
          Log.info('PlatformMusicService: Permission denied to access music library');
          throw Exception('Permission denied to access music library');
        }
      }

      // 获取所有歌曲
      Log.info('PlatformMusicService: Querying songs from audio library');
      final songs = await _audioQuery!.querySongs(
        sortType: SongSortType.DISPLAY_NAME,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      Log.info('PlatformMusicService: Found ${songs.length} songs');

      // 转换为我们的Song模型
      final result = songs.map((song) => tune.Song(song.getMap)).toList();
      Log.info('PlatformMusicService: Converted to ${result.length} tune.Song objects');
      return result;
    } catch (e) {
      Log.info('PlatformMusicService: Failed to fetch songs: $e');
      // 提供更具体的错误信息
      if (e is MissingPluginException) {
        throw Exception('当前平台不支持音乐扫描功能。此功能仅在Android和iOS设备上可用。');
      } else if (e.toString().contains('Permission denied')) {
        throw Exception('没有音乐库访问权限，请在设置中授予相关权限。');
      }
      throw Exception('扫描音乐失败: $e');
    }
  }

  @override
  Future<List<tune.Song>> searchSongs(String query) async {
    Log.info('PlatformMusicService: searchSongs called with query: $query');
    if (_audioQuery == null) {
      Log.info('PlatformMusicService: Audio query is null in search, returning empty list');
      return [];
    }

    if (query.isEmpty) {
      Log.info('PlatformMusicService: Query is empty, calling getAllSongs');
      return await getAllSongs();
    }

    try {
      // 检查并请求权限（如果支持）
      Log.info('PlatformMusicService: Checking permissions before searching songs');
      bool permissionStatus = await _checkPermissionStatus();
      Log.info('PlatformMusicService: Permission status for search: $permissionStatus');
      
      if (!permissionStatus) {
        Log.info('PlatformMusicService: Requesting permissions for search');
        bool status = await _requestPermission();
        Log.info('PlatformMusicService: Permission request status for search: $status');
        if (!status) {
          Log.info('PlatformMusicService: Permission denied to access music library for search');
          throw Exception('Permission denied to access music library');
        }
      }
      
      // 使用path参数进行搜索
      Log.info('PlatformMusicService: Querying songs with search query: $query');
      final songs = await _audioQuery!.querySongs(
        sortType: SongSortType.DISPLAY_NAME,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        path: query,
      );
      Log.info('PlatformMusicService: Found ${songs.length} songs in search');

      final result = songs.map((song) => tune.Song(song.getMap)).toList();
      Log.info('PlatformMusicService: Converted to ${result.length} tune.Song objects in search');
      return result;
    } catch (e) {
      Log.info('PlatformMusicService: Failed to search songs: $e');
      // 如果搜索失败，回退到过滤所有歌曲的方式
      try {
        Log.info('PlatformMusicService: Falling back to getAllSongs for search');
        final allSongs = await getAllSongs();
        final queryLower = query.toLowerCase();
        final filteredSongs = allSongs.where((song) {
          return song.title.toLowerCase().contains(queryLower) ||
              (song.artist != null && song.artist!.toLowerCase().contains(queryLower)) ||
              (song.album != null && song.album!.toLowerCase().contains(queryLower));
        }).toList();
        Log.info('PlatformMusicService: Filtered ${filteredSongs.length} songs from ${allSongs.length} total songs');
        return filteredSongs;
      } catch (fallbackError) {
        Log.info('PlatformMusicService: Fallback also failed: $fallbackError');
        throw Exception('Failed to search songs: $e, fallback also failed: $fallbackError');
      }
    }
  }
}