import 'package:flutter/material.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/features/home/presentation/widgets/music_library/song_list_tile.dart';

class MusicLibraryList extends StatelessWidget {
  final List<Song> songs;
  final Map<String, List<Song>>? groupedSongs;
  final String? groupBy;

  const MusicLibraryList({
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
                    ...entry.value.map((song) => SongListTile(song: song)),
                    const Divider(),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          return SongListTile(song: songs[index]);
        },
      );
    }
  }
}