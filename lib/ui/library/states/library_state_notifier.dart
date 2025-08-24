import 'dart:convert';
import 'dart:io' show File;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/player_state_notifier.dart' show PlayerStateNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart' as scanner_provider;
import 'package:tune/utils/logger.dart';

class LibraryStateNotifier extends StateNotifier<LibraryState> {
  final Ref _ref;

  LibraryStateNotifier(this._ref) : super(LibraryState.initial());

  void toggleGridView() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSelectedMenuItemIndex(int index) {
    state = state.copyWith(selectedMenuItemIndex: index);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setSongs(List<Song> songs) {
    state = state.copyWith(songs: songs, isLoading: false);
  }

  void setError(String error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  // 音乐扫描相关方法
  void startScanning() {
    state = state.copyWith(scanStatus: ScanStatus.scanning, errorMessage: null);
  }

  void updateScanProgress(double progress) {
    state = state.copyWith(scanProgress: progress);
  }

  void completeScan(List<Song> songs) {
    state = state.copyWith(
      scanStatus: ScanStatus.completed,
      foundSongs: songs,
      scanProgress: songs.length.toDouble(),
    );
  }

  void scanError(String error) {
    state = state.copyWith(
      scanStatus: ScanStatus.error,
      errorMessage: error,
    );
  }

  void resetScan() {
    state = state.copyWith(
      scanStatus: ScanStatus.idle,
      foundSongs: [],
      scanProgress: 0.0,
      errorMessage: null,
    );
  }

  /// 添加扫描到的歌曲到音乐库
  Future<void> addScannedSongsToLibrary() async {
    try {
      setLoading(true);
      
      // 获取扫描到的歌曲
      final scannedSongs = state.foundSongs;
      
      // 更新音乐库
      setSongs([...state.songs, ...scannedSongs]);
      
      // 保存到持久化存储
      await _saveScannedSongs(scannedSongs);
      
      // 重置扫描状态
      resetScan();
    } catch (e) {
      Log.error('添加扫描歌曲到音乐库失败: $e');
      setError('添加扫描歌曲到音乐库失败: $e');
    }
  }

  /// 保存扫描到的歌曲到持久化存储
  Future<void> _saveScannedSongs(List<Song> songs) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(path.join(dir.path, 'scanned_songs.json'));
      
      // 将歌曲转换为可序列化的Map列表
      final songsData = songs.map((song) {
        return {
          'id': song.id,
          'uri': song.uri,
          'data': song.data,
          'displayName': song.displayName,
          'title': song.title,
          'album': song.album,
          'artist': song.artist,
          'duration': song.duration,
          'size': song.size,
          'dateAdded': song.dateAdded,
          // 注意：Song模型中没有dateModified字段，使用dateAdded替代
          'dateModified': song.dateAdded,
          // 注意：Song模型中没有track字段，使用trackNumber替代
          'track': song.trackNumber,
          'sampleRate': song.sampleRate,
          'trackNumber': song.trackNumber,
          'trackTotal': song.trackTotal,
          'discNumber': song.discNumber,
          'totalDisc': song.totalDisc,
          'lyrics': song.lyrics,
          'genres': song.genres,
          'performers': song.performers,
          'language': song.language,
          'type': song.type,
          'isFavorite': song.isFavorite,
        };
      }).toList();
      
      await file.writeAsString(jsonEncode(songsData));
    } catch (e) {
      // 错误处理，但不中断主流程
      Log.error('保存歌曲数据失败: $e');
    }
  }

  /// 从持久化存储加载歌曲
  Future<List<Song>> _loadScannedSongs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(path.join(dir.path, 'scanned_songs.json'));
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> songsData = jsonDecode(jsonString);
        return songsData.map((data) => Song(data as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // 错误处理，但不中断主流程
      Log.error('加载歌曲数据失败: $e');
    }
    return [];
  }

  /// 加载音乐库
  void loadLibrary() async {
    setLoading(true);

    try {
      // 首先尝试从持久化存储加载歌曲
      List<Song> songs = await _loadScannedSongs();
      
      // 如果持久化存储中没有歌曲，则从扫描服务获取
      if (songs.isEmpty) {
        final scanner = _ref.read(scanner_provider.crossPlatformMusicScannerProvider);
        songs = await scanner.getAllSongs();
      }

      setSongs(songs);
    } catch (e) {
      Log.error('加载音乐库失败: $e');
      setError('加载音乐库失败: $e');
    }
  }

  /// 搜索歌曲
  void searchSongs(String query) async {
    setLoading(true);

    try {
      final scanner = _ref.read(scanner_provider.crossPlatformMusicScannerProvider);
      final songs = await scanner.searchSongs(query);

      setSongs(songs);
    } catch (e) {
      Log.error('搜索歌曲失败: $e');
      setError('搜索歌曲失败: $e');
    }
  }

  /// 播放歌曲并设置播放列表
  void playSong(Song song) {
    try {
      Log.info('准备播放歌曲: ${song.title}');
      final playerNotifier = _ref.read(playerStateNotifierProvider.notifier);

      // 获取当前显示的所有歌曲作为播放列表
      final List<Song> allSongs = [...state.songs, ...state.foundSongs];
      Log.info('构建播放列表，共${allSongs.length}首歌曲');

      // 查找歌曲在列表中的索引
      final index = allSongs.indexWhere((s) => s.id == song.id);
      Log.info('歌曲索引: $index');

      // 设置播放列表
      playerNotifier.setPlaylist(allSongs, index);

      // 播放指定歌曲
      playerNotifier.playSong(song);
      Log.info('歌曲播放请求已发送');
    } catch (e, stackTrace) {
      Log.error('播放歌曲失败: $e\nStack trace: $stackTrace');
    }
  }

  /// 移除自定义扫描路径
  void removeCustomPath(String pathToRemove) {
    try {
      final persistenceService = _ref.read(sharedPreferencesServiceProvider);
      final customPaths = persistenceService.getStringList('custom_scan_paths') ?? [];
      
      // 从列表中移除指定路径
      final updatedPaths = List<String>.from(customPaths)..remove(pathToRemove);
      
      // 保存更新后的路径列表
      persistenceService.setStringList('custom_scan_paths', updatedPaths);
    } catch (e) {
      Log.error('移除自定义扫描路径失败: $e');
    }
  }

  /// 清空搜索结果
  void clearSearch() {
    state = state.copyWith(
      searchResults: const [],
      searchQuery: '',
      isLoading: false,
      errorMessage: null,
    );
  }
}