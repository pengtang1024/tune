import 'package:flutter/material.dart';

class AlbumCoverWidget extends StatelessWidget {
  const AlbumCoverWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,   // 调整封面宽度
      height: 64,  // 调整封面高度
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        size: 32,  // 调整图标尺寸
        color: Colors.grey[600],
      ),
    );
  }
}