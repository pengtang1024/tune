import 'package:tune/domain/models/song.dart';

// 扫描状态枚举
enum ScanStatus { idle, scanning, completed, error }

class LibraryState {
  final bool isGridView;
  final String searchQuery;
  final int selectedMenuItemIndex;
  final List<Song> songs;
  final bool isLoading;
  final String? errorMessage;
  final List<Song> searchResults;

  // 音乐扫描相关字段
  final ScanStatus scanStatus;
  final double scanProgress;
  final List<Song> foundSongs;
  final String statusMessage;

  LibraryState({
    required this.isGridView,
    required this.searchQuery,
    required this.selectedMenuItemIndex,
    required this.songs,
    required this.isLoading,
    this.errorMessage,
    required this.searchResults,
    this.scanStatus = ScanStatus.idle,
    this.scanProgress = 0.0,
    this.foundSongs = const [],
    this.statusMessage = '',
  });

  /// 检查是否有扫描结果
  bool get hasScannedResults => foundSongs.isNotEmpty;

  LibraryState copyWith({
    bool? isGridView,
    String? searchQuery,
    int? selectedMenuItemIndex,
    List<Song>? songs,
    bool? isLoading,
    String? errorMessage,
    List<Song>? searchResults,
    ScanStatus? scanStatus,
    double? scanProgress,
    List<Song>? foundSongs,
    String? statusMessage,
  }) {
    return LibraryState(
      isGridView: isGridView ?? this.isGridView,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMenuItemIndex: selectedMenuItemIndex ?? this.selectedMenuItemIndex,
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchResults: searchResults ?? this.searchResults,
      scanStatus: scanStatus ?? this.scanStatus,
      scanProgress: scanProgress ?? this.scanProgress,
      foundSongs: foundSongs ?? this.foundSongs,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  static LibraryState initial() {
    return LibraryState(
      isGridView: false,
      searchQuery: '',
      selectedMenuItemIndex: 0,
      songs: const [],
      isLoading: false,
      searchResults: const [],
    );
  }
}