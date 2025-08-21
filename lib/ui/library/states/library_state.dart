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

  // 音乐扫描相关字段
  final ScanStatus scanStatus;
  final double scanProgress;
  final List<Song> foundSongs;
  final String statusMessage;
  
  // 批量选择相关字段
  final bool isMultiSelectMode;
  final Set<Song> selectedSongs;

  LibraryState({
    required this.isGridView,
    required this.searchQuery,
    required this.selectedMenuItemIndex,
    required this.songs,
    required this.isLoading,
    this.errorMessage,
    this.scanStatus = ScanStatus.idle,
    this.scanProgress = 0.0,
    this.foundSongs = const [],
    this.statusMessage = '',
    this.isMultiSelectMode = false,
    this.selectedSongs = const {},
  });

  LibraryState copyWith({
    bool? isGridView,
    String? searchQuery,
    int? selectedMenuItemIndex,
    List<Song>? songs,
    bool? isLoading,
    String? errorMessage,
    ScanStatus? scanStatus,
    double? scanProgress,
    List<Song>? foundSongs,
    String? statusMessage,
    bool? isMultiSelectMode,
    Set<Song>? selectedSongs,
  }) {
    return LibraryState(
      isGridView: isGridView ?? this.isGridView,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMenuItemIndex: selectedMenuItemIndex ?? this.selectedMenuItemIndex,
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      scanStatus: scanStatus ?? this.scanStatus,
      scanProgress: scanProgress ?? this.scanProgress,
      foundSongs: foundSongs ?? this.foundSongs,
      statusMessage: statusMessage ?? this.statusMessage,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
      selectedSongs: selectedSongs ?? this.selectedSongs,
    );
  }

  static LibraryState initial() {
    return LibraryState(
      isGridView: false,
      searchQuery: '',
      selectedMenuItemIndex: 0,
      songs: [],
      isLoading: false,
      isMultiSelectMode: false,
      selectedSongs: const {},
    );
  }

  List<Song> get searchResults {
    if (searchQuery.isEmpty) {
      return songs;
    }

    final query = searchQuery.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          (song.artist.toLowerCase().contains(query)) ||
          (song.album.toLowerCase().contains(query));
    }).toList();
  }
}
