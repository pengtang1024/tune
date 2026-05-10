import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class LibraryCategoriesPanel extends StatelessWidget {
  final List<Song> songs;
  const LibraryCategoriesPanel({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    final categories = _calculateCategories();

    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: AppDesignSystem.textTheme.titleMedium?.copyWith(
              fontWeight: AppDesignSystem.fontWeightBold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _CategoryList(title: 'Top Artists', items: categories.topArtists)),
                const VerticalDivider(width: 1),
                Expanded(child: _CategoryList(title: 'Top Albums', items: categories.topAlbums)),
                const VerticalDivider(width: 1),
                Expanded(child: _CategoryList(title: 'Genres', items: categories.topGenres)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LibraryCategories _calculateCategories() {
    final artistCount = <String, int>{};
    final albumCount = <String, int>{};
    final genreCount = <String, int>{};
    for (final song in songs) {
      if (song.artist.isNotEmpty) artistCount[song.artist] = (artistCount[song.artist] ?? 0) + 1;
      if (song.album.isNotEmpty) albumCount[song.album] = (albumCount[song.album] ?? 0) + 1;
      if (song.genre != null && song.genre!.isNotEmpty) genreCount[song.genre!] = (genreCount[song.genre!] ?? 0) + 1;
    }
    return LibraryCategories(
      topArtists: _topItems(artistCount, 8),
      topAlbums: _topItems(albumCount, 8),
      topGenres: _topItems(genreCount, 8),
    );
  }

  List<CategoryItem> _topItems(Map<String, int> items, int limit) {
    final sorted = items.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => CategoryItem(name: e.key, count: e.value)).toList();
  }
}

class _CategoryList extends StatelessWidget {
  final String title;
  final List<CategoryItem> items;

  const _CategoryList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppDesignSystem.textTheme.labelMedium?.copyWith(
            fontWeight: AppDesignSystem.fontWeightSemiBold,
            color: AppDesignSystem.primary,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        ...items.take(5).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: AppDesignSystem.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class CategoryItem {
  final String name;
  final int count;
  CategoryItem({required this.name, required this.count});
}

class LibraryCategories {
  final List<CategoryItem> topArtists;
  final List<CategoryItem> topAlbums;
  final List<CategoryItem> topGenres;
  LibraryCategories({
    required this.topArtists,
    required this.topAlbums,
    required this.topGenres,
  });
}
