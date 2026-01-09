import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/widgets/modern_song_card.dart';
import 'package:tune/ui/widgets/modern_card.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化音乐网格组件
/// 提供优雅的音乐列表展示效果
class SongGridWidget extends StatelessWidget {
  final List<Song> songs;
  final String searchQuery;
  final String localizedNoSongsFound;
  final Function(Song)? onSongTap;
  final Function(Song)? onSongPlay;
  final Function(Song)? onSongMore;
  final String? currentlyPlayingId;
  final SongGridStyle style;

  const SongGridWidget({
    super.key,
    required this.songs,
    required this.searchQuery,
    required this.localizedNoSongsFound,
    this.onSongTap,
    this.onSongPlay,
    this.onSongMore,
    this.currentlyPlayingId,
    this.style = SongGridStyle.list,
  });

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _filterSongs(songs, searchQuery);

    if (songs.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.library_music_rounded,
        localizedNoSongsFound,
        '扫描本地音乐文件夹来开始使用',
      );
    }

    if (filteredSongs.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.search_off_rounded,
        '没有找到匹配的歌曲',
        '尝试使用不同的搜索关键词',
      );
    }

    return switch (style) {
      SongGridStyle.grid => _buildGridView(filteredSongs),
      SongGridStyle.list => _buildListView(filteredSongs),
      SongGridStyle.compact => _buildCompactView(filteredSongs),
    };
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ModernCard(
        width: 320,
        padding: const EdgeInsets.all(AppDesignSystem.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDesignSystem.albumCoverSize120,
              height: AppDesignSystem.albumCoverSize120,
              decoration: BoxDecoration(
                color: AppDesignSystem.primary.withOpacity(0.1),
                borderRadius: AppDesignSystem.borderRadius24,
              ),
              child: Icon(
                icon,
                size: AppDesignSystem.iconSize64,
                color: AppDesignSystem.primary,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: AppDesignSystem.fontWeightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacing8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark 
                    ? AppDesignSystem.neutral400 
                    : AppDesignSystem.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Song> filteredSongs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕宽度动态调整列数
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final childAspectRatio = _calculateChildAspectRatio(crossAxisCount);

        return GridView.builder(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: AppDesignSystem.spacing16,
            mainAxisSpacing: AppDesignSystem.spacing16,
          ),
          itemCount: filteredSongs.length,
          itemBuilder: (context, index) {
            final song = filteredSongs[index];
            return ModernSongCard.grid(
              song: song,
              onTap: () => onSongTap?.call(song),
              onPlay: () => onSongPlay?.call(song),
              onMore: () => onSongMore?.call(song),
              isPlaying: song.id == currentlyPlayingId,
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<Song> filteredSongs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing8),
      itemCount: filteredSongs.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppDesignSystem.spacing4),
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return ModernSongCard.list(
          song: song,
          onTap: () => onSongTap?.call(song),
          onPlay: () => onSongPlay?.call(song),
          onMore: () => onSongMore?.call(song),
          isPlaying: song.id == currentlyPlayingId,
        );
      },
    );
  }

  Widget _buildCompactView(List<Song> filteredSongs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing4),
      itemCount: filteredSongs.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppDesignSystem.spacing2),
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return ModernSongCard.compact(
          song: song,
          onTap: () => onSongTap?.call(song),
          onPlay: () => onSongPlay?.call(song),
          isPlaying: song.id == currentlyPlayingId,
        );
      },
    );
  }

  int _calculateCrossAxisCount(double maxWidth) {
    if (maxWidth > 1400) return 7;
    if (maxWidth > 1200) return 6;
    if (maxWidth > 1000) return 5;
    if (maxWidth > 800) return 4;
    if (maxWidth > 600) return 3;
    return 2;
  }

  double _calculateChildAspectRatio(int crossAxisCount) {
    // 根据列数调整宽高比，确保卡片显示效果良好
    switch (crossAxisCount) {
      case 2:
      case 3:
        return 1.2; // 更宽的比例，适合显示更多信息
      case 4:
      case 5:
        return 1.0; // 标准比例
      case 6:
      case 7:
        return 0.8; // 更紧凑的比例，适应更多列
      default:
        return 1.0;
    }
  }

  List<Song> _filterSongs(List<Song> songs, String query) {
    if (query.isEmpty) {
      return songs;
    }

    final lowerQuery = query.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

/// 音乐网格显示样式
enum SongGridStyle {
  /// 网格视图，适合大屏幕浏览
  grid,
  
  /// 列表视图，适合详细展示
  list,
  
  /// 紧凑视图，适合大量音乐展示
  compact,
}