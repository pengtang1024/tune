import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/search/application/online_search_controller.dart';
import 'package:tune/features/search/domain/online_search_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/utils/duration_format.dart';

Future<void> showOnlineSearchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _OnlineSearchSheet(),
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
    final sourceNames = {for (final source in sources) source.id: source.name};
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      CompactTokens.space16,
                      0,
                      CompactTokens.space16,
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainer,
                              hintText: context.loc.searchOnlineHint,
                              hintStyle: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
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
                          onPressed: search?.isSearching == true
                              ? null
                              : _search,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
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
                      sourceNames: sourceNames,
                      onPlay: _play,
                      onAddToQueue: _addToQueue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _play(SourceScanResult result, int index) async {
    final songs = result.songs;
    if (songs.isEmpty) return;
    await ref
        .read(playbackControllerProvider.notifier)
        .playQueue(songs, startIndex: index.clamp(0, songs.length - 1));
    if (mounted) Navigator.of(context).pop();
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
        CompactTokens.space8,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.loc.searchOnlineDescription,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.loc.close,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OnlineSearchState? search;
  final Map<String, String> sourceNames;
  final Future<void> Function(SourceScanResult result, int index) onPlay;
  final ValueChanged<Song> onAddToQueue;

  const _Body({
    required this.search,
    required this.sourceNames,
    required this.onPlay,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    final state = search ?? const OnlineSearchState();
    if (state.isSearching) {
      return _SearchingView(state: state, sourceNames: sourceNames);
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
        subtitle: state.message ?? context.loc.searchNoMatchDescription,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.space12,
        CompactTokens.space8,
        CompactTokens.space12,
        CompactTokens.space24,
      ),
      children: [
        for (final result in visibleGroups)
          _SourceGroup(
            result: result,
            sourceName: sourceNames[result.sourceId] ?? result.sourceId,
            onPlay: onPlay,
            onAddToQueue: onAddToQueue,
          ),
      ],
    );
  }
}

class _SearchingView extends StatelessWidget {
  final OnlineSearchState state;
  final Map<String, String> sourceNames;

  const _SearchingView({required this.state, required this.sourceNames});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = state.progress.entries.toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(CompactTokens.space20),
      children: [
        Text(
          context.loc.searchSearching(state.query),
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
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
                    sourceNames[entry.key] ?? entry.key,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${(entry.value * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
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
  final String sourceName;
  final Future<void> Function(SourceScanResult result, int index) onPlay;
  final ValueChanged<Song> onAddToQueue;

  const _SourceGroup({
    required this.result,
    required this.sourceName,
    required this.onPlay,
    required this.onAddToQueue,
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
                  sourceName,
                  result.message ?? context.loc.searchFailedShort,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
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
            CompactTokens.space8,
            CompactTokens.space8,
            CompactTokens.space8,
            CompactTokens.space4,
          ),
          child: Row(
            children: [
              Text(
                sourceName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: CompactTokens.space8),
              Text(
                context.loc.searchResultCount(result.songs.length),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onPlay(result, 0),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CompactTokens.space8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 11),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(context.loc.searchPlayAll),
              ),
            ],
          ),
        ),
        for (var index = 0; index < result.songs.length; index++)
          _SongRow(
            song: result.songs[index],
            onPlay: () => onPlay(result, index),
            onAddToQueue: () => onAddToQueue(result.songs[index]),
          ),
        const SizedBox(height: CompactTokens.space4),
      ],
    );
  }
}

class _SongRow extends StatelessWidget {
  final Song song;
  final VoidCallback onPlay;
  final VoidCallback onAddToQueue;

  const _SongRow({
    required this.song,
    required this.onPlay,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      song.artist,
      song.album,
    ].where((value) => value.trim().isNotEmpty).join(' · ');

    return InkWell(
      onTap: onPlay,
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
              size: 38,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              song.duration > 0
                  ? formatDuration(Duration(milliseconds: song.duration))
                  : '--:--',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              tooltip: context.loc.searchAddToQueue,
              onPressed: onAddToQueue,
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
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
            Icon(icon, size: 34, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: CompactTokens.space12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: CompactTokens.space4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
