import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

class CompactAlbumArt extends StatelessWidget {
  final String? path;
  final String? imageUrl;
  final double size;

  const CompactAlbumArt({
    super.key,
    required this.path,
    required this.size,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(CompactTokens.radius12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: radius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).round(),
        errorBuilder: (context, error, stackTrace) => _Placeholder(size: size),
      );
    }

    if (path != null && path!.isNotEmpty) {
      return Image.file(
        File(path!),
        fit: BoxFit.cover,
        cacheWidth: (size * 2).round(),
        errorBuilder: (context, error, stackTrace) => _Placeholder(size: size),
      );
    }

    return _Placeholder(size: size);
  }
}

class _Placeholder extends StatelessWidget {
  final double size;

  const _Placeholder({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: (size * 0.22).clamp(24, 48),
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    );
  }
}
