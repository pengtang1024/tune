import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/providers/artwork_providers.dart';

/// Square album artwork with a quiet fallback.
class ArtworkThumb extends ConsumerWidget {
  final String? path;
  final String? imageUrl;
  final double size;
  final double radius;

  const ArtworkThumb({
    super.key,
    required this.path,
    required this.size,
    this.imageUrl,
    this.radius = CompactTokens.radius10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: _image(context, ref),
    );
  }

  Widget _image(BuildContext context, WidgetRef ref) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final picture = ref.watch(artworkImageProvider(imageUrl!));
      return Image(
        image: ResizeImage.resizeIfNeeded((size * 2).round(), null, picture),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }

    if (path != null && path!.isNotEmpty) {
      return Image.file(
        File(path!),
        fit: BoxFit.cover,
        cacheWidth: (size * 2).round(),
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }

    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Icon(
        Icons.album_rounded,
        size: size * 0.42,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
      ),
    );
  }
}
