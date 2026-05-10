import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/music_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class LibraryOverviewSection extends ConsumerWidget {
  const LibraryOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final AsyncValue<List<Song>> songsAsync = ref.watch(_songsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.music_library,
          style: AppDesignSystem.textTheme.titleLarge?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing12),
        ModernCard(
          padding: const EdgeInsets.all(AppDesignSystem.spacing20),
          child: songsAsync.when(
            data: (songs) {
              final songCount = songs.length;
              final albumCount = songs
                  .map((s) => s.album)
                  .where((a) => a.isNotEmpty)
                  .toSet()
                  .length;
              final artistCount = songs
                  .map((s) => s.artist)
                  .where((a) => a.isNotEmpty)
                  .toSet()
                  .length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(icon: Icons.music_note, count: songCount, label: loc.songs, color: AppDesignSystem.primary),
                  _StatItem(icon: Icons.album, count: albumCount, label: loc.albums, color: AppDesignSystem.secondary),
                  _StatItem(icon: Icons.person, count: artistCount, label: loc.artists, color: AppDesignSystem.tertiary),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

final _songsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return repository.getAllSongs();
});

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  String _formatCount(int c) {
    if (c < 1000) return '$c';
    if (c < 1000000) return '${(c / 1000).toStringAsFixed(1)}K';
    return '${(c / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppDesignSystem.borderRadius16,
          ),
          child: Icon(icon, size: AppDesignSystem.iconSize32, color: color),
        ),
        const SizedBox(height: AppDesignSystem.spacing12),
        Text(
          _formatCount(count),
          style: AppDesignSystem.textTheme.titleMedium?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        Text(
          label,
          style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
          ),
        ),
      ],
    );
  }
}
