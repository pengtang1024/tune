import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/widgets/song_card_widget.dart';

class SongGridWidget extends StatelessWidget {
  final List<Song> songs;
  final String searchQuery;
  final String localizedNoSongsFound;

  const SongGridWidget({
    super.key,
    required this.songs,
    required this.searchQuery,
    required this.localizedNoSongsFound,
  });

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _filterSongs(songs, searchQuery);

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizedNoSongsFound,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizedNoSongsFound,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // 根据屏幕宽度采用不同的布局策略
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // 在大屏幕上（宽度>800）使用网格布局，小屏幕上使用列表布局
        if (screenWidth > 800) {
          // PC端使用网格布局
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,       // 保持列数
              childAspectRatio: 2.8,   // 调整宽高比使卡片高度适中
              crossAxisSpacing: 12,    // 调整交叉轴间距
              mainAxisSpacing: 12,     // 调整主轴间距
            ),
            itemCount: filteredSongs.length,
            itemBuilder: (context, index) {
              return SongCardWidget(song: filteredSongs[index], index: index);
            },
          );
        } else {
          // 移动端使用列表布局
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSongs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SongCardWidget(song: filteredSongs[index], index: index),
              );
            },
          );
        }
      },
    );
  }

  /// 根据查询字符串过滤歌曲列表
  ///
  /// 该函数接收一个歌曲列表和一个查询字符串，返回一个包含匹配查询条件的歌曲的新列表。
  /// 查询不区分大小写，将同时匹配歌曲标题、艺术家和专辑名称。
  ///
  /// 参数:
  ///   [songs] - 要过滤的歌曲列表
  ///   [query] - 用于过滤的查询字符串
  ///
  /// 返回:
  ///   返回过滤后的歌曲列表。如果查询字符串为空，则返回原始歌曲列表。
  ///
  /// 示例:
  /// ```dart
  /// final songs = [/* 歌曲列表 */];
  /// final filtered = _filterSongs(songs, 'love');
  /// // 返回标题、艺术家或专辑中包含'love'的歌曲
  /// ```
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
