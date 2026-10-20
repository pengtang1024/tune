import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/search/application/online_search_controller.dart';
import 'package:tune/features/search/domain/online_search_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/compact_sheet.dart';
import 'package:tune/shared/ui/track_click_area.dart';
import 'package:tune/shared/ui/track_detail_sheet.dart';
import 'package:tune/shared/ui/track_fact_strip.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
import 'package:tune/shared/utils/duration_format.dart';

Future<void> showOnlineSearchSheet(BuildContext context) {
  return showCompactSheet<void>(
    context,
    (context) => const _OnlineSearchSheet(),
  );
}

class _OnlineSearchSheet extends ConsumerStatefulWidget {
  const _OnlineSearchSheet();

  @override
  ConsumerState<_OnlineSearchSheet> createState() => _OnlineSearchSheetState();
}

class _OnlineSearchSheetState extends ConsumerState<_OnlineSearchSheet> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    _focusNode.unfocus();
    ref.read(onlineSearchControllerProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final search = ref.watch(onlineSearchControllerProvider).valueOrNull;
    final sources = localizedSources(
      context.loc,
      ref.watch(musicSourcesControllerProvider).valueOrNull?.sources ??
          const <MusicSourceConfig>[],
    );
    final sourceLabels = sourceLabelsOf(context.loc, sources);
    final settings = ref.watch(settingsControllerProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CompactTokens.sheetRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              _Header(
                onClose: () => Navigator.of(context).pop(),
                colors: theme.colorScheme,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CompactTokens.space20,
                  0,
                  CompactTokens.space20,
                  CompactTokens.space12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        focusNode: _focusNode,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: theme.textTheme.bodyMedium?.copyWith(),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainer,
                          hintText: context.loc.searchOnlineHint,
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: CompactTokens.icon18,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: CompactTokens.borderRadius8,
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: CompactTokens.borderRadius8,
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: CompactTokens.borderRadius8,
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: CompactTokens.space8,
                            vertical: CompactTokens.space12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: CompactTokens.space8),
                    FilledButton(
                      onPressed: search?.isSearching == true ? null : _search,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, CompactTokens.controlMedium),
                        padding: const EdgeInsets.symmetric(
                          horizontal: CompactTokens.space16,
                        ),
                      ),
                      child: Text(context.loc.search),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              Expanded(
                child: _Body(
                  search: search,
                  sourceLabels: sourceLabels,
                  onPlay: _play,
                  onDoubleTap: _like,
                  onAddToQueue: _addToQueue,
                  waitsForDoubleClick: settings.onlyLikeOnDoubleClick,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _play(SourceScanResult result, int index) async {
    final songs = result.songs;
    if (songs.isEmpty) return;
    final start = index.clamp(0, songs.length - 1);
    await ref.read(listPlaybackProvider).playFrom(songs[start], songs, start);
    if (mounted) Navigator.of(context).pop();
  }

  /// Marks the track, or takes the mark away when it is already there.
  void _like(Song song) {
    ref.read(favoritesControllerProvider.notifier).toggle(song.uri);
  }

  void _addToQueue(Song song) {
    ref.read(playbackControllerProvider.notifier).addToQueue(song);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.searchAddedToQueue(song.title)),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  final ColorScheme colors;

  const _Header({required this.onClose, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.space20,
        CompactTokens.space16,
        CompactTokens.space20,
        CompactTokens.space12,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: CompactTokens.borderRadius8,
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              size: CompactTokens.icon18,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: CompactTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.searchOnlineTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.loc.searchOnlineDescription,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TuneTooltip(
            message: context.loc.close,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: CompactTokens.icon18),
              style: IconButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OnlineSearchState? search;
  final Map<String, SourceLabel> sourceLabels;
  final Future<void> Function(SourceScanResult result, int index) onPlay;
  final ValueChanged<Song> onDoubleTap;
  final ValueChanged<Song> onAddToQueue;

  /// Whether a click waits for a possible second click before it plays.
  ///
  /// A double click that only likes the track may not play it, so the click
  /// has to wait to see whether a second click follows.
  final bool waitsForDoubleClick;

  const _Body({
    required this.search,
    required this.sourceLabels,
    required this.onPlay,
    required this.onDoubleTap,
    required this.onAddToQueue,
    required this.waitsForDoubleClick,
  });

  @override
  Widget build(BuildContext context) {
    final state = search ?? const OnlineSearchState();
    if (state.isSearching) {
      return _SearchingView(state: state, sourceLabels: sourceLabels);
    }
    if (!state.hasQuery) {
      return _EmptyView(
        icon: Icons.travel_explore_rounded,
        title: context.loc.searchOnlinePrompt,
        subtitle: context.loc.searchOnlinePromptDescription,
      );
    }
    if (state.results.isEmpty) {
      return _EmptyView(
        icon: Icons.search_off_rounded,
        title: context.loc.searchNoResults,
        subtitle: state.message ?? context.loc.searchNoResultsDescription,
      );
    }

    final groups = state.orderedResults.toList(growable: false);
    final visibleGroups = groups.where(
      (result) => result.songs.isNotEmpty || !result.isSuccess,
    );
    if (visibleGroups.isEmpty) {
      return _EmptyView(
        icon: Icons.search_off_rounded,
        title: context.loc.searchNoMatch,
        subtitle: state.message ?? context.loc.searchNoResultsDescription,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.space20,
        CompactTokens.space8,
        CompactTokens.space20,
        CompactTokens.space24,
      ),
      children: [
        for (final result in visibleGroups)
          _SourceGroup(
            result: result,
            sourceLabel:
                sourceLabels[result.sourceId] ??
                SourceLabel(name: result.sourceId, type: result.sourceId),
            onPlay: onPlay,
            onDoubleTap: onDoubleTap,
            onAddToQueue: onAddToQueue,
            waitsForDoubleClick: waitsForDoubleClick,
          ),
      ],
    );
  }
}

class _SearchingView extends StatelessWidget {
  final OnlineSearchState state;
  final Map<String, SourceLabel> sourceLabels;

  const _SearchingView({required this.state, required this.sourceLabels});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = state.progress.entries.toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(CompactTokens.space20),
      children: [
        Text(
          context.loc.searchSearching(state.query),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: CompactTokens.space12),
        if (entries.isEmpty)
          const LinearProgressIndicator(minHeight: 3)
        else
          for (final entry in entries) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    sourceLabels[entry.key]?.name ?? entry.key,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${(entry.value * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: entry.value <= 0 ? null : entry.value,
                minHeight: 3,
                backgroundColor: theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: CompactTokens.space12),
          ],
      ],
    );
  }
}

class _SourceGroup extends StatelessWidget {
  final SourceScanResult result;
  final SourceLabel sourceLabel;
  final Future<void> Function(SourceScanResult result, int index) onPlay;
  final ValueChanged<Song> onDoubleTap;
  final ValueChanged<Song> onAddToQueue;

  /// Whether a click waits for a possible second click before it plays.
  ///
  /// A double click that only likes the track may not play it, so the click
  /// has to wait to see whether a second click follows.
  final bool waitsForDoubleClick;

  const _SourceGroup({
    required this.result,
    required this.sourceLabel,
    required this.onPlay,
    required this.onDoubleTap,
    required this.onAddToQueue,
    required this.waitsForDoubleClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!result.isSuccess && result.songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: CompactTokens.space8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              result.status == SourceScanStatus.needsConfiguration
                  ? Icons.tune_rounded
                  : Icons.error_outline_rounded,
              size: CompactTokens.icon16,
              color: result.status == SourceScanStatus.needsConfiguration
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: CompactTokens.space8),
            Expanded(
              child: Text(
                context.loc.searchSourceError(
                  sourceLabel.name,
                  result.message ?? context.loc.searchFailedShort,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            0,
            CompactTokens.space8,
            0,
            CompactTokens.space4,
          ),
          child: Row(
            children: [
              SourceBadge(label: sourceLabel, dense: true),
              const SizedBox(width: CompactTokens.space8),
              Text(
                context.loc.libraryTrackCount(result.songs.length),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onPlay(result, 0),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, CompactTokens.controlTiny),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CompactTokens.space8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: CompactTokens.icon16,
                ),
                label: Text(context.loc.searchPlayAll),
              ),
            ],
          ),
        ),
        for (var index = 0; index < result.songs.length; index++)
          _SongRow(
            song: result.songs[index],
            source: sourceLabel,
            onPlay: () => onPlay(result, index),
            onDoubleTap: () => onDoubleTap(result.songs[index]),
            onAddToQueue: () => onAddToQueue(result.songs[index]),
            waitsForDoubleClick: waitsForDoubleClick,
          ),
        const SizedBox(height: CompactTokens.space4),
      ],
    );
  }
}

class _SongRow extends StatelessWidget {
  final Song song;
  final SourceLabel source;
  final VoidCallback onPlay;
  final VoidCallback onDoubleTap;
  final VoidCallback onAddToQueue;

  /// Whether a click waits for a possible second click before it plays.
  ///
  /// A double click that only likes the track may not play it, so the click
  /// has to wait to see whether a second click follows.
  final bool waitsForDoubleClick;

  const _SongRow({
    required this.song,
    required this.source,
    required this.onPlay,
    required this.onDoubleTap,
    required this.onAddToQueue,
    required this.waitsForDoubleClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      song.artist,
      song.album,
    ].where((value) => value.trim().isNotEmpty).join(' · ');

    return TrackClickArea(
      onClick: onPlay,
      onDoubleClick: onDoubleTap,
      waitsForDoubleClick: waitsForDoubleClick,
      borderRadius: CompactTokens.borderRadius8,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CompactTokens.space8,
          vertical: CompactTokens.space6,
        ),
        child: Row(
          children: [
            ArtworkThumb(
              path: song.albumArtPath,
              imageUrl: song.artworkUrl,
              size: CompactTokens.artworkRow,
              radius: CompactTokens.radius8,
            ),
            const SizedBox(width: CompactTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: CompactTokens.space8),
            TrackFactStrip(song: song),
            const SizedBox(width: CompactTokens.space8),
            Text(
              song.duration > 0
                  ? formatDuration(Duration(milliseconds: song.duration))
                  : '--:--',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TuneTooltip(
              message: context.loc.trackDetailsTooltip,
              child: IconButton(
                onPressed: () => showTrackDetailSheet(context, song, source: source),
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: CompactTokens.icon16,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            TuneTooltip(
              message: context.loc.searchAddToQueue,
              child: IconButton(
                onPressed: onAddToQueue,
                icon: const Icon(
                  Icons.playlist_add_rounded,
                  size: CompactTokens.icon18,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CompactTokens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: CompactTokens.illustration,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: CompactTokens.space12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: CompactTokens.space4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
