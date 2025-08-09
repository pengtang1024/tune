import 'package:flutter/material.dart';
import 'package:tune/domain/entities/song.dart';

class SongList extends StatelessWidget {
  final List<Song> songs;
  final Function(Song) onSongSelected;

  const SongList({
    super.key,
    required this.songs,
    required this.onSongSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          title: Text(song.title),
          subtitle: Text('${song.artist} - ${song.album}'),
          onTap: () => onSongSelected(song),
        );
      },
    );
  }
}
