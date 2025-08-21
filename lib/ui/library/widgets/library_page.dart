import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/utils/device_utils.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索栏
            _buildSearchBar(),
            const SizedBox(height: 16),

            // 音乐库统计信息
            _buildLibraryStats(),
            const SizedBox(height: 16),

            // 歌曲列表（九宫格布局）
            Expanded(
              child: _buildSongGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.loc.search_songs, // 使用本地化字符串
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            // 使用push而不是go，这样可以正确返回到上一个页面
            context.push('/music-scan');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.sync),
        ),
      ],
    );
  }

  Widget _buildLibraryStats() {
    final songsAsync = ref.watch(songsProvider);

    return songsAsync.when(
      data: (songs) {
        final totalSongs = songs.length;
        final totalArtists = songs.map((song) => song.artist).toSet().length;
        final totalAlbums = songs.map((song) => song.album).toSet().length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(context.loc.songs, totalSongs.toString()), // 使用本地化字符串
            _buildStatItem(context.loc.artists, totalArtists.toString()), // 使用本地化字符串
            _buildStatItem(context.loc.albums, totalAlbums.toString()), // 使用本地化字符串
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('${context.loc.load_stats_failed}: $error'), // 使用本地化字符串
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSongGrid() {
    final songsAsync = ref.watch(songsProvider);

    return songsAsync.when(
      data: (songs) {
        // 根据搜索查询过滤歌曲
        final filteredSongs = _searchQuery.isEmpty
            ? songs
            : songs.where((song) {
                // 搜索匹配：标题、艺术家或专辑
                return song.title.toLowerCase().contains(_searchQuery) ||
                    song.artist.toLowerCase().contains(_searchQuery) ||
                    song.album.toLowerCase().contains(_searchQuery);
              }).toList();

        if (filteredSongs.isEmpty) {
          return Center(
            child: Text(context.loc.no_songs_found), // 使用本地化字符串
          );
        }

        // 计算列数（根据屏幕宽度动态调整）
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = (screenWidth / 180).floor().clamp(1, 10);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, // 控制网格项的宽高比
          ),
          itemCount: filteredSongs.length,
          itemBuilder: (context, index) {
            final song = filteredSongs[index];
            return _buildSongCard(song);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('${context.loc.load_songs_failed}: $error'), // 使用本地化字符串
      ),
    );
  }

  Widget _buildSongCard(Song song) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // 点击歌曲卡片时的处理逻辑
          final notifier = ref.read(playerStateNotifierProvider.notifier);
          notifier.playSong(song);
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 专辑封面占位符
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Icon(
                Icons.music_note,
                size: 48,
                color: Colors.grey[600],
              ),
            ),
            // 歌曲信息
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 歌曲标题
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 艺术家
                  Text(
                    song.artist,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 专辑
                  Text(
                    song.album,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}