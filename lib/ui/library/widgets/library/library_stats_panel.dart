import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class LibraryStatsPanel extends StatelessWidget {
  final List<Song> songs;
  const LibraryStatsPanel({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library Stats',
            style: AppDesignSystem.textTheme.titleMedium?.copyWith(
              fontWeight: AppDesignSystem.fontWeightBold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _StatCard(icon: Icons.music_note, title: 'Songs', value: '${stats.totalSongs}'),
                const SizedBox(width: AppDesignSystem.spacing12),
                _StatCard(icon: Icons.person, title: 'Artists', value: '${stats.uniqueArtists}'),
                const SizedBox(width: AppDesignSystem.spacing12),
                _StatCard(icon: Icons.album, title: 'Albums', value: '${stats.uniqueAlbums}'),
                const SizedBox(width: AppDesignSystem.spacing12),
                _StatCard(icon: Icons.category, title: 'Genres', value: '${stats.uniqueGenres}'),
                const SizedBox(width: AppDesignSystem.spacing12),
                _StatCard(icon: Icons.access_time, title: 'Duration', value: stats.totalDuration),
                const SizedBox(width: AppDesignSystem.spacing12),
                _StatCard(icon: Icons.storage, title: 'Size', value: stats.totalSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LibraryStats _calculateStats() {
    final totalSongs = songs.length;
    final uniqueArtists = songs.map((s) => s.artist).where((a) => a.isNotEmpty).toSet().length;
    final uniqueAlbums = songs.map((s) => s.album).where((a) => a.isNotEmpty).toSet().length;
    final uniqueGenres = songs.map((s) => s.genre).where((g) => g != null && g.isNotEmpty).toSet().length;
    final totalMs = songs.fold<int>(0, (s, song) => s + song.duration);
    final totalBytes = songs.fold<int>(0, (s, song) => s + (song.size ?? 0));

    return LibraryStats(
      totalSongs: totalSongs,
      uniqueArtists: uniqueArtists,
      uniqueAlbums: uniqueAlbums,
      uniqueGenres: uniqueGenres,
      totalDuration: _fmtDuration(totalMs),
      totalSize: _fmtSize(totalBytes),
    );
  }

  String _fmtDuration(int ms) {
    final d = Duration(milliseconds: ms);
    return d.inHours > 0 ? '${d.inHours}h ${d.inMinutes.remainder(60)}m' : '${d.inMinutes}m';
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing8),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystem.neutral800 : AppDesignSystem.neutral50,
        borderRadius: AppDesignSystem.borderRadius12,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppDesignSystem.iconSize24, color: AppDesignSystem.primary),
          const SizedBox(height: AppDesignSystem.spacing6),
          Text(value, style: AppDesignSystem.textTheme.titleSmall?.copyWith(fontWeight: AppDesignSystem.fontWeightBold)),
          Text(title, style: AppDesignSystem.textTheme.labelSmall?.copyWith(color: AppDesignSystem.neutral500)),
        ],
      ),
    );
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
