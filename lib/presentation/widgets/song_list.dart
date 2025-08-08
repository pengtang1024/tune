import 'package:flutter/material.dart';
import 'package:tune/core/utils/localization_delegate.dart';
import 'package:tune/domain/entities/song.dart';

class SongList extends StatelessWidget {
  final List<Song> songs;
  final Function(Song)? onSongTap;

  const SongList({super.key, required this.songs, this.onSongTap});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    if (songs.isEmpty) {
      return Center(
        child: Text(localizations.songListNoSongs),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.music_note),
          ),
          title: Text(song.title),
          subtitle: Text(song.artist),
          trailing: Text(
            _formatDuration(Duration(milliseconds: song.duration)),
            style: const TextStyle(fontSize: 12),
          ),
          onTap: onSongTap != null ? () => onSongTap!(song) : null,
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}