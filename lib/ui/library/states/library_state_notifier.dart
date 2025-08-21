import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/player_state_notifier.dart';
import 'package:path_provider/path_provider.dart';

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
    state = state.copyWith(
      scanStatus: ScanStatus.scanning,
      statusMessage: '正在扫描音乐...',
    );
  }

  /// 更新扫描进度
  void updateScanProgress(double progress) {
    state = state.copyWith(scanProgress: progress);
  }

  void addFoundSong(Song song) {
    final updatedSongs = List<Song>.from(state.foundSongs)..add(song);
    state = state.copyWith(foundSongs: updatedSongs);
  }

  void completeScanning(List<Song> songs) {
    state = state.copyWith(
      scanStatus: ScanStatus.completed,
      foundSongs: songs,
      statusMessage: '扫描完成，找到 ${songs.length} 首歌曲',
    );
  }

  void setScanError(String error) {
    state = state.copyWith(
      scanStatus: ScanStatus.error,
      errorMessage: error,
      statusMessage: '扫描出错: $error',
    );
  }

  void resetScan() {
    state = state.copyWith(
      scanStatus: ScanStatus.idle,
      scanProgress: 0.0,
      foundSongs: const [],
      statusMessage: '',
      errorMessage: null,
    );
  }

  void scanMusic() async {
    try {
      startScanning();

      // 调用真正的音乐扫描服务
      final scanner = _ref.read(crossPlatformMusicScannerProvider);

      // 使用带进度更新的扫描方法
      final songs = await scanner.scanMusicInDirectoriesWithProgress(
        scanner.getDefaultMusicPaths(),
        (progress) {
          // 在主线程更新UI进度
          updateScanProgress(progress);
        },
      );

      completeScanning(songs);
      // 保存扫描结果到持久化存储
      await _saveScannedSongs(songs);
    } catch (e) {
      setScanError('扫描失败: $e');
    }
  }

  /// 扫描自定义路径中的音乐
  void scanCustomPaths() async {
    try {
      startScanning();

      // 获取自定义扫描路径
      final persistenceService = _ref.read(sharedPreferencesServiceProvider);
      final customPaths = persistenceService.getStringList('custom_scan_paths') ?? [];

      if (customPaths.isEmpty) {
        setScanError('没有设置自定义扫描路径');
        return;
      }

      // 调用真正的音乐扫描服务
      final scanner = _ref.read(crossPlatformMusicScannerProvider);
      final songs = await scanner.scanMusicInDirectoriesWithProgress(
        customPaths,
        (progress) {
          // 在主线程更新UI进度
          updateScanProgress(progress);
        },
      );

      completeScanning(songs);
      // 保存扫描结果到持久化存储
      await _saveScannedSongs(songs);
    } catch (e) {
      setScanError('扫描失败: $e');
    }
  }

  /// 将扫描到的歌曲添加到音乐库
  void addScannedSongsToLibrary() {
    if (state.foundSongs.isNotEmpty) {
      // 创建一个映射，用于快速查找已存在的歌曲
      final existingSongsMap = <int, Song>{};
      for (final song in state.songs) {
        existingSongsMap[song.id] = song;
      }
      
      // 创建更新后的歌曲列表
      final updatedSongs = List<Song>.from(state.songs);
      
      // 处理扫描到的歌曲
      int updatedCount = 0;
      int addedCount = 0;
      
      for (final newSong in state.foundSongs) {
        if (existingSongsMap.containsKey(newSong.id)) {
          // 如果歌曲已存在，则更新它
          final index = updatedSongs.indexWhere((song) => song.id == newSong.id);
          updatedSongs[index] = newSong;
          updatedCount++;
        } else {
          // 如果是新歌曲，则添加它
          updatedSongs.add(newSong);
          addedCount++;
        }
      }
      
      state = state.copyWith(
        songs: updatedSongs,
        foundSongs: const [],
        scanStatus: ScanStatus.idle,
        statusMessage: '已更新 $updatedCount 首歌曲，新增 $addedCount 首歌曲',
      );
      // 保存到持久化存储
      _saveScannedSongs(updatedSongs);
    }
  }

  void removeCustomPath(String path) {
    // TODO: 实现移除自定义路径的逻辑
  }

  /// 保存扫描到的歌曲到持久化存储
  Future<void> _saveScannedSongs(List<Song> songs) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(path.join(dir.path, 'scanned_songs.json'));
      
      // 手动构建歌曲数据映射
      final List<Map<String, dynamic>> songsData = songs.map((song) {
        return {
          'id': song.id,
          'title': song.title,
          'artist': song.artist,
          'album': song.album,
          'duration': song.duration,
          'uri': song.uri,
          'dateAdded': song.dateAdded,
          'genre': song.genre,
          'year': song.year,
          'bitrate': song.bitrate,
          'sampleRate': song.sampleRate,
          'trackNumber': song.trackNumber,
          'trackTotal': song.trackTotal,
          'discNumber': song.discNumber,
          'totalDisc': song.totalDisc,
          'lyrics': song.lyrics,
          'genres': song.genres,
          'performers': song.performers,
          'language': song.language,
          'size': song.size,
          'type': song.type,
          'isFavorite': song.isFavorite,
        };
      }).toList();
      
      await file.writeAsString(jsonEncode(songsData));
    } catch (e) {
      // 错误处理，但不中断主流程
      print('保存歌曲数据失败: $e');
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
      print('加载歌曲数据失败: $e');
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
        final scanner = _ref.read(crossPlatformMusicScannerProvider);
        songs = await scanner.getAllSongs();
      }

      setSongs(songs);
    } catch (e) {
      setError('加载音乐库失败: $e');
    }
  }

  /// 搜索歌曲
  void searchSongs(String query) async {
    setLoading(true);

    try {
      final scanner = _ref.read(crossPlatformMusicScannerProvider);
      final songs = await scanner.searchSongs(query);

      setSongs(songs);
    } catch (e) {
      setError('搜索歌曲失败: $e');
    }
  }

  /// 播放歌曲并设置播放列表
  void playSong(Song song) {
    final playerNotifier = _ref.read(playerStateNotifierProvider.notifier);

    // 获取当前显示的所有歌曲作为播放列表
    final List<Song> allSongs = [...state.songs, ...state.foundSongs];

    // 查找歌曲在列表中的索引
    final index = allSongs.indexWhere((s) => s.id == song.id);

    // 设置播放列表
    playerNotifier.setPlaylist(allSongs, index);

    // 播放指定歌曲
    playerNotifier.playSong(song);
  }
}