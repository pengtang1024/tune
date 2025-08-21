import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/player_state_notifier.dart';

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
      final songs = await scanner.scanMusic();

      completeScanning(songs);
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
      final songs = await scanner.scanMusicInDirectories(customPaths);
      
      completeScanning(songs);
    } catch (e) {
      setScanError('扫描失败: $e');
    }
  }
  
  /// 将扫描到的歌曲添加到音乐库
  void addScannedSongsToLibrary() {
    if (state.foundSongs.isNotEmpty) {
      final updatedSongs = List<Song>.from(state.songs)..addAll(state.foundSongs);
      state = state.copyWith(
        songs: updatedSongs,
        foundSongs: const [],
        scanStatus: ScanStatus.idle,
        statusMessage: '',
      );
    }
  }

  void removeCustomPath(String path) {
    // TODO: 实现移除自定义路径的逻辑
  }
  
  /// 加载音乐库
  void loadLibrary() {
    // 这里应该从持久化存储中加载歌曲
    // 目前我们只是模拟一下
    setLoading(true);
    
    // 模拟异步加载
    Future.delayed(const Duration(milliseconds: 500), () {
      // 实际项目中这里应该从数据库或文件中加载歌曲
      setSongs(state.songs); // 保持现有歌曲
      setLoading(false);
    });
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