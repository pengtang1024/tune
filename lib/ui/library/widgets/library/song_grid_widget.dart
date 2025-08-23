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
              localizedNoSongsFound, // 使用本地化文本而不是硬编码
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕宽度动态调整列数
        final crossAxisCount = constraints.maxWidth > 1200
            ? 6
            : constraints.maxWidth > 1000
                ? 5
                : constraints.maxWidth > 800
                    ? 4
                    : constraints.maxWidth > 600
                        ? 3
                        : 2;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredSongs.length,
          itemBuilder: (context, index) {
            return SongCardWidget(song: filteredSongs[index]);
          },
        );
      },
    );
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