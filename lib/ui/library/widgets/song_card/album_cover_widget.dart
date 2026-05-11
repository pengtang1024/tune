import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class AlbumCoverWidget extends StatelessWidget {
  final String? albumArtPath;
  final double size;

  const AlbumCoverWidget({super.key, this.albumArtPath, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
        borderRadius: AppDesignSystem.borderRadius8,
      ),
      child: albumArtPath != null && albumArtPath!.isNotEmpty
          ? ClipRRect(
              borderRadius: AppDesignSystem.borderRadius8,
              child: Image.file(
                File(albumArtPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _defaultIcon(),
              ),
            )
          : _defaultIcon(),
    );
  }

  Widget _defaultIcon() {
    return const Icon(Icons.music_note_rounded, size: 32, color: Colors.white);
  }
}
