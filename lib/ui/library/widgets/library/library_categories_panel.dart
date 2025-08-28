import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';

class LibraryCategoriesPanel extends StatelessWidget {
  final List<Song> songs;

  const LibraryCategoriesPanel({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    final categories = _calculateCategories();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '音乐分类',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // 艺术家分类
                  Expanded(
                    child: _buildCategoryList(
                      context,
                      title: '热门艺术家',
                      items: categories.topArtists,
                    ),
                  ),
                  const VerticalDivider(),
                  // 专辑分类
                  Expanded(
                    child: _buildCategoryList(
                      context,
                      title: '热门专辑',
                      items: categories.topAlbums,
                    ),
                  ),
                  const VerticalDivider(),
                  // 流派分类
                  Expanded(
                    child: _buildCategoryList(
                      context,
                      title: '流派分布',
                      items: categories.topGenres,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context,
      {required String title, required List<CategoryItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: SizedBox(
                  width: 40,
                  child: Text('${item.count}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  LibraryCategories _calculateCategories() {
    // 计算艺术家分布
    final artistCount = <String, int>{};
    for (final song in songs) {
      if (song.artist != null && song.artist!.isNotEmpty) {
        artistCount[song.artist!] = (artistCount[song.artist!] ?? 0) + 1;
      }
    }

    // 计算专辑分布
    final albumCount = <String, int>{};
    for (final song in songs) {
      if (song.album != null && song.album!.isNotEmpty) {
        albumCount[song.album!] = (albumCount[song.album!] ?? 0) + 1;
      }
    }

    // 计算流派分布
    final genreCount = <String, int>{};
    for (final song in songs) {
      if (song.genre != null && song.genre!.isNotEmpty) {
        genreCount[song.genre!] = (genreCount[song.genre!] ?? 0) + 1;
      }
    }

    // 获取前N个热门项
    final topArtists = _getTopItems(artistCount, 10);
    final topAlbums = _getTopItems(albumCount, 10);
    final topGenres = _getTopItems(genreCount, 10);

    return LibraryCategories(
      topArtists: topArtists,
      topAlbums: topAlbums,
      topGenres: topGenres,
    );
  }

  List<CategoryItem> _getTopItems(Map<String, int> items, int limit) {
    final sortedItems = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedItems.take(limit).map((e) {
      return CategoryItem(name: e.key, count: e.value);
    }).toList();
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