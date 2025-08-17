import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';

class MusicCardWidget extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const MusicCardWidget({
    Key? key,
    required this.song,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        child: ListTile(
          title: Text(song.title),
          subtitle: Text('${song.artist} - ${song.album}'),
          trailing: Text(_formatDuration(song.duration)),
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatDuration(int durationInSeconds) {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}