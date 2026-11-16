import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/features/library/domain/library_album.dart';
import 'package:tune/features/library/presentation/library_queue_all_button.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/utils/duration_format.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The heading of one album.
///
/// It keeps the height of the library heading, so opening an album does not
/// push the tracks down: the cover, the name and the two actions of the album
/// fit in the row the library title used. Going back is the first row of the
/// list below, not a second arrow here.
class LibraryAlbumHeader extends StatelessWidget {
  final LibraryAlbum album;
  final VoidCallback onPlay;
  final VoidCallback onAddAll;

  const LibraryAlbumHeader({
    super.key,
    required this.album,
    required this.onPlay,
    required this.onAddAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = CompactTypography.asDisplay(
      theme.textTheme.displayMedium,
      size: CompactTypeScale.displayMedium,
      height: 0.95,
    );
    final name = album.name.isEmpty
        ? context.loc.libraryUnknownAlbum
        : album.name;
    final artist = album.isUnknown && album.hasMultipleArtists
        ? context.loc.libraryVariousArtists
        : (album.artist.isEmpty
              ? context.loc.playerUnknownArtist
              : album.artist);

    return SizedBox(
      height: CompactTokens.controlDefault,
      child: Row(
        children: [
          ArtworkThumb(
            path: album.coverPath,
            imageUrl: album.coverUrl,
            size: CompactTokens.libraryArtwork,
            radius: CompactTokens.radius6,
          ),
          const SizedBox(width: CompactTokens.space8),
          Text(
            context.loc.nowPlayingDetailAlbum,
            style: CompactTypography.mono(
              theme.colorScheme.primary,
              size: CompactTypeScale.mark,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          Flexible(
            flex: 3,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
          const SizedBox(width: CompactTokens.space12),
          Expanded(
            flex: 2,
            child: Text(
              '$artist · ${_countOf(context, album)}'
              ' · ${formatDuration(Duration(milliseconds: album.durationInMillis))}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: CompactTokens.space12),
          TuneTooltip(
            message: context.loc.searchPlayAll,
            child: IconButton(
              onPressed: onPlay,
              icon: const Icon(
                Icons.play_arrow_rounded,
                size: CompactTokens.icon20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: CompactTokens.controlTiny,
                height: CompactTokens.controlTiny,
              ),
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          LibraryQueueAllButton(onPressed: onAddAll),
        ],
      ),
    );
  }
}

/// 打开一个「专辑」时的计数口径随内容分类走：播客数单集，有声书数章节，
/// 音效数条目，音乐数曲目。
String _countOf(BuildContext context, LibraryAlbum album) =>
    switch (album.kind) {
      ContentKind.podcast => context.loc.libraryEpisodeCount(album.trackCount),
      ContentKind.audiobook => context.loc.libraryChapterCount(
        album.trackCount,
      ),
      ContentKind.soundEffect => context.loc.libraryEffectCount(
        album.trackCount,
      ),
      _ => context.loc.libraryTrackCount(album.trackCount),
    };
