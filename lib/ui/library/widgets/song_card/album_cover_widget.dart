import 'package:flutter/material.dart';

class AlbumCoverWidget extends StatelessWidget {
  const AlbumCoverWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        size: 32,
        color: Colors.grey[600],
      ),
    );
  }
}