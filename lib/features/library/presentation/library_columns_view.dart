import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/dead_songs_controller.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/dense_icon_action.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/source_label.dart';
import 'package:tune/shared/ui/track_click_area.dart';
import 'package:tune/shared/ui/track_details_button.dart';
import 'package:tune/shared/ui/track_position.dart';
import 'package:tune/shared/utils/duration_format.dart';

/// The wall of the library: two tracks per line.
///
/// A cell keeps two lines instead of squeezing one: the title on top, the
/// artist and album under it. The tail holds the duration and the heart;
/// the pointer brings the details and the queue action out. The order is
/// left to right, top to bottom, with one continuous number.
class LibraryColumnsView extends StatelessWidget {
  final List<Song> songs;
  final Map<String, SourceLabel> sourceLabels;
  final bool waitsForDoubleClick;
  final ScrollController? controller;

  const LibraryColumnsView({
    super.key,
    required this.songs,
    required this.sourceLabels,
    required this.waitsForDoubleClick,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - CompactTokens.pageGutter * 2;
        if (width < 860) {
          return const SizedBox.shrink();
        }
        return GridView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            0,
            CompactTokens.pageGutter,
            CompactTokens.space8,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: CompactTokens.space8,
            mainAxisSpacing: 0,
            mainAxisExtent: 40,
          ),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Consumer(
              builder: (context, ref, child) {
                final (selected, playing) = ref.watch(
                  playbackControllerProvider.select((value) {
                    final selected = value.currentSong?.uri == song.uri;
                    return (selected, selected && value.isPlaying);
                  }),
                );
                final isFavorite = ref.watch(
                  favoritesControllerProvider.select(
                    (value) => value.contains(song.uri),
                  ),
                );
                return _ColumnCard(
                  song: song,
                  index: index,
                  selected: selected,
                  playing: playing,
                  isFavorite: isFavorite,
                  unavailable: ref.watch(deadSongsProvider).contains(song.uri),
                  source: sourceLabel(song, sourceLabels),
                  waitsForDoubleClick: waitsForDoubleClick,
                  onTap: () => ref.read(listPlaybackProvider).play(song),
                  onDoubleTap: () => ref
                      .read(favoritesControllerProvider.notifier)
                      .mark(song.uri),
                  onAddToQueue: () => ref
                      .read(playbackControllerProvider.notifier)
                      .addToQueue(song),
                  onToggleFavorite: () => ref
                      .read(favoritesControllerProvider.notifier)
                      .toggle(song.uri),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ColumnCard extends StatefulWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final bool isFavorite;
  final bool unavailable;
  final SourceLabel? source;
  final bool waitsForDoubleClick;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onAddToQueue;
  final VoidCallback onToggleFavorite;

  const _ColumnCard({
    required this.song,
    required this.index,
    required this.selected,
    required this.playing,
    required this.isFavorite,
    required this.unavailable,
    required this.source,
    required this.waitsForDoubleClick,
    required this.onTap,
    required this.onDoubleTap,
    required this.onAddToQueue,
    required this.onToggleFavorite,
  });

  @override
  State<_ColumnCard> createState() => _ColumnCardState();
}

class _ColumnCardState extends State<_ColumnCard> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final song = widget.song;
    final artist = song.artist.trim().isEmpty
        ? context.loc.playerUnknownArtist
        : song.artist;
    final album = song.album.trim();
    final second = [
      artist,
      if (album.isNotEmpty) album,
    ].join(' · ');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: widget.selected
            ? accent.withValues(alpha: 0.06)
            : Colors.transparent,
        child: TrackClickArea(
          onClick: widget.onTap,
          onDoubleClick: widget.onDoubleTap,
          waitsForDoubleClick: widget.waitsForDoubleClick,
          hoverColor: accent.withValues(alpha: 0.04),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 2,
                  color: widget.selected ? accent : Colors.transparent,
                ),
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: CompactTokens.space8,
              vertical: 4,
            ),
            child: Row(
              children: [
                TrackPosition(
                  index: widget.index,
                  selected: widget.selected,
                  playing: widget.playing,
                  width: 18,
                ),
                const SizedBox(width: CompactTokens.space6),
                ArtworkThumb(
                  path: song.albumArtPath,
                  imageUrl: song.artworkUrl,
                  size: 28,
                  radius: CompactTokens.radius6,
                ),
                const SizedBox(width: CompactTokens.space8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title.isEmpty
                            ? context.loc.trackUnknownTitle
                            : song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: widget.selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.selected ? accent : null,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              second,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (widget.source != null) ...[
                            const SizedBox(width: CompactTokens.space4),
                            SourceBadge(label: widget.source!, dense: true),
                          ],
                          if (widget.unavailable) ...[
                            const SizedBox(width: CompactTokens.space4),
                            Icon(
                              Icons.link_off_rounded,
                              size: CompactTokens.icon12,
                              color: theme.colorScheme.error,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CompactTokens.space4),
                SizedBox(
                  width: 72,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: _hovering
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TrackDetailsButton(
                                song: song,
                                source: widget.source,
                                isFavorite: widget.isFavorite,
                                onToggleFavorite: widget.onToggleFavorite,
                                dense: true,
                              ),
                              DenseIconAction(
                                icon: Icons.add_rounded,
                                tooltip: context.loc.libraryAddToQueue,
                                onPressed: widget.onAddToQueue,
                              ),
                              FavoriteButton(
                                isFavorite: widget.isFavorite,
                                onPressed: widget.onToggleFavorite,
                                dense: true,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatDuration(
                                  Duration(
                                    milliseconds: song.durationInMillis,
                                  ),
                                ),
                                style: CompactTypography.mono(
                                  theme.colorScheme.onSurfaceVariant,
                                  size: CompactTypeScale.mark,
                                ),
                              ),
                              const SizedBox(width: CompactTokens.space4),
                              FavoriteButton(
                                isFavorite: widget.isFavorite,
                                onPressed: widget.onToggleFavorite,
                                dense: true,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
