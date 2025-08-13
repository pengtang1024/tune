import 'package:flutter/material.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/features/home/presentation/widgets/music_library/song_grid_tile.dart';

class MusicLibraryGrid extends StatelessWidget {
  final List<Song> songs;
  final Map<String, List<Song>>? groupedSongs;
  final String? groupBy;

  const MusicLibraryGrid({
    super.key,
    required this.songs,
    this.groupedSongs,
    this.groupBy,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedSongs != null && groupBy != null && groupedSongs!.isNotEmpty) {
      return CustomScrollView(
        slivers: [
          ...groupedSongs!.entries.map(
            (entry) => SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: entry.value.map((song) => SongGridTile(song: song)).toList(),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: songs.map((song) => SongGridTile(song: song)).toList(),
      );
    }
  }
}