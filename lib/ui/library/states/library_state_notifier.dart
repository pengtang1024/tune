import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/domain/models/song.dart';

class LibraryStateNotifier extends StateNotifier<LibraryState> {
  LibraryStateNotifier() : super(LibraryState.initial());

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
  
  void scanMusic() {
    // 模拟扫描过程
    startScanning();
    
    // 这里应该调用实际的音乐扫描逻辑
    // 现在只是模拟扫描过程
    Future.delayed(const Duration(seconds: 2), () {
      completeScanning([]);
    });
  }
  
  void removeCustomPath(String path) {
    // TODO: 实现移除自定义路径的逻辑
  }
}