import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';

class TrackInfo extends StatelessWidget {
  final Song? song;
  final String? errorMessage;

  const TrackInfo({super.key, required this.song, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = song == null || song!.title.isEmpty
        ? context.loc.no_song_playing
        : song!.title;
    final artist = song == null
        ? context.loc.select_a_song_to_play
        : song!.artist.isNotEmpty
        ? song!.artist
        : '未知艺术家';
    final album = song?.album.isNotEmpty == true ? song!.album : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: CompactTokens.space6),
        Text(
          album == null ? artist : '$artist · $album',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (errorMessage != null && errorMessage!.isNotEmpty) ...[
          const SizedBox(height: CompactTokens.space4),
          Text(
            errorMessage!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
