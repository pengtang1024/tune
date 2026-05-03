import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class LibraryStatsPanel extends StatelessWidget {
  final List<Song> songs;

  const LibraryStatsPanel({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows || 
                     defaultTargetPlatform == TargetPlatform.macOS || 
                     defaultTargetPlatform == TargetPlatform.linux;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '音乐库统计',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 20),
            if (isDesktop)
              _buildDesktopLayout(context, stats)
            else
              _buildMobileLayout(context, stats)
          ],
        ),
      ),
    );
  }

  /// 构建桌面端布局
  Widget _buildDesktopLayout(BuildContext context, LibraryStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 0) / 6;
        return SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatCard(
                context: context,
                width: itemWidth,
                icon: Icons.music_note,
                title: '歌曲总数',
                value: stats.totalSongs.toString(),
              ),
              _buildStatCard(
                context: context,
                width: itemWidth,
                icon: Icons.person,
                title: '艺术家数量',
                value: stats.uniqueArtists.toString(),
              ),
              _buildStatCard(
                context: context,
                width: itemWidth,
                icon: Icons.album,
                title: '专辑数量',
                value: stats.uniqueAlbums.toString(),
              ),
              _buildStatCard(
                context: context,
                width: itemWidth,
                icon: Icons.category,
                title: '流派数量',
                value: stats.uniqueGenres.toString(),
              ),
              _buildStatCard(
                context: context,
                width: itemWidth,
                icon: Icons.access_time,
                title: '总时长',
                value: stats.totalDuration,
              ),
              _buildStatCard(
                context: context,
                width: itemWidth,
                icon: Icons.storage,
                title: '总大小',
                value: stats.totalSize,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建移动端布局
  Widget _buildMobileLayout(BuildContext context, LibraryStats stats) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(
            context: context,
            width: 120,
            icon: Icons.music_note,
            title: '歌曲总数',
            value: stats.totalSongs.toString(),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            context: context,
            width: 120,
            icon: Icons.person,
            title: '艺术家数量',
            value: stats.uniqueArtists.toString(),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            context: context,
            width: 120,
            icon: Icons.album,
            title: '专辑数量',
            value: stats.uniqueAlbums.toString(),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            context: context,
            width: 120,
            icon: Icons.category,
            title: '流派数量',
            value: stats.uniqueGenres.toString(),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            context: context,
            width: 120,
            icon: Icons.access_time,
            title: '总时长',
            value: stats.totalDuration,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            context: context,
            width: 120,
            icon: Icons.storage,
            title: '总大小',
            value: stats.totalSize,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required double width,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  LibraryStats _calculateStats() {
    final totalSongs = songs.length;
    
    // 计算唯一艺术家数量
    final uniqueArtists = songs
        .map((song) => song.artist)
        .where((artist) => artist.isNotEmpty)
        .toSet()
        .length;
    
    // 计算唯一专辑数量
    final uniqueAlbums = songs
        .map((song) => song.album)
        .where((album) => album.isNotEmpty)
        .toSet()
        .length;
    
    // 计算唯一流派数量
    final uniqueGenres = songs
        .map((song) => song.genre)
        .where((genre) => genre != null && genre.isNotEmpty)
        .toSet()
        .length;
    
    // 计算总时长
    final totalDurationMs = songs.fold<int>(
        0, (sum, song) => sum + song.duration);
    final totalDuration = _formatDuration(totalDurationMs);
    
    // 计算总大小
    final totalSizeBytes =
        songs.fold<int>(0, (sum, song) => sum + (song.size ?? 0));
    final totalSize = _formatFileSize(totalSizeBytes);

    return LibraryStats(
      totalSongs: totalSongs,
      uniqueArtists: uniqueArtists,
      uniqueAlbums: uniqueAlbums,
      uniqueGenres: uniqueGenres,
      totalDuration: totalDuration,
      totalSize: totalSize,
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    } else {
      return '$minutes分钟';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

class LibraryStats {
  final int totalSongs;
  final int uniqueArtists;
  final int uniqueAlbums;
  final int uniqueGenres;
  final String totalDuration;
  final String totalSize;

  LibraryStats({
    required this.totalSongs,
    required this.uniqueArtists,
    required this.uniqueAlbums,
    required this.uniqueGenres,
    required this.totalDuration,
    required this.totalSize,
  });
}