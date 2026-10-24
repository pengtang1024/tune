import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/utils/text_order.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/favorites/domain/favorites_state.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_empty_state.dart';
import 'package:tune/features/library/presentation/library_queue_all_button.dart';
import 'package:tune/features/library/presentation/library_scan_status_bar.dart';
import 'package:tune/features/library/presentation/library_toolbar.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/search/presentation/online_search_sheet.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/empty_state_view.dart';
import 'package:tune/shared/ui/page_heading.dart';
import 'package:tune/shared/ui/source_label.dart';

/// The library page.
///
/// The page wires the controller to the widgets; a track is always rendered
/// by [LibraryTrackCard].
class LibraryPane extends ConsumerStatefulWidget {
  const LibraryPane({super.key});

  @override
  ConsumerState<LibraryPane> createState() => _LibraryPaneState();
}

class _LibraryPaneState extends ConsumerState<LibraryPane> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryControllerProvider);
    ref.listen<String?>(
      libraryControllerProvider.select((value) => value.valueOrNull?.query),
      (previous, next) {
        if (next == null || next == _searchController.text) return;
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
    );

    if (library.isLoading && !library.hasValue) {
      return const Center(child: CompactSpinner.large());
    }

    final state = library.valueOrNull;
    if (state == null) {
      return EmptyStateView(
        icon: Icons.error_outline_rounded,
        title: context.loc.libraryLoadFailedTitle,
        subtitle: '${library.error ?? context.loc.unknownError}',
        action: FilledButton(
          onPressed: () => ref.invalidate(libraryControllerProvider),
          child: Text(context.loc.retry),
        ),
      );
    }

    final settings = ref.watch(settingsControllerProvider);
    final favorites = ref.watch(favoritesControllerProvider);
    final playback = ref.watch(
      playbackControllerProvider.select(
        (value) => (value.currentSong?.uri, value.isPlaying),
      ),
    );
    final sourceConfigs = ref.watch(
      musicSourcesControllerProvider.select(
        (value) => value.valueOrNull?.sources ?? const [],
      ),
    );
    final sourceLabels = sourceLabelsOf(context.loc, sourceConfigs);
    final songs = state.filteredSongs;
    final hasSourceIssues = state.sourceSummaries.values.any(
      (summary) => summary.status != SourceScanStatus.success,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            CompactTokens.pageTopPadding,
            CompactTokens.pageGutter,
            CompactTokens.pageHeadingGap,
          ),
          child: PageHeading(
            eyebrow: context.loc.libraryEyebrow,
            title: context.loc.libraryTitle,
            subtitle: context.loc.librarySubtitle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LibraryQueueAllButton(
                  onPressed: songs.isEmpty ? null : () => _addAllToQueue(songs),
                ),
                const SizedBox(width: CompactTokens.space8),
                OutlinedButton.icon(
                  onPressed: () => showOnlineSearchSheet(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, CompactTokens.controlDefault),
                    padding: const EdgeInsets.symmetric(
                      horizontal: CompactTokens.space12,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  icon: const Icon(
                    Icons.travel_explore_rounded,
                    size: CompactTokens.icon16,
                  ),
                  label: Text(context.loc.searchOnlineTitle),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            0,
            CompactTokens.pageGutter,
            CompactTokens.space12,
          ),
          child: LibraryToolbar(
            controller: _searchController,
            query: state.query,
            filteredCount: songs.length,
            sources: _availableSources(state, sourceLabels, sourceConfigs),
            sourceLabels: sourceLabels,
            sourceFilter: state.sourceFilter,
            scanning: state.isScanning,
            onQueryChanged: (value) {
              ref.read(libraryControllerProvider.notifier).setQuery(value);
            },
            onClearQuery: _clearQuery,
            onSourceFilter: (value) {
              ref
                  .read(libraryControllerProvider.notifier)
                  .setSourceFilter(value);
            },
            onScan: state.isScanning || state.isLoading ? null : _scan,
          ),
        ),
        if (state.isScanning || state.errorMessage != null || hasSourceIssues)
          LibraryScanStatusBar(state: state),
        Expanded(
          child: state.isLoading
              ? const Center(child: CompactSpinner.large())
              : _body(
                  state,
                  songs,
                  playback.$1,
                  playback.$2,
                  sourceLabels,
                  favorites,
                  settings.onlyLikeOnDoubleClick,
                ),
        ),
        if (!state.hasSongs && !state.isScanning && state.errorMessage == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CompactTokens.pageGutter,
              0,
              CompactTokens.pageGutter,
              CompactTokens.space12,
            ),
            child: Text(
              context.loc.libraryScanPaths(
                settings.effectiveScanPaths.join('  ·  '),
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// Sources that own at least one track of the library, in weight order.
  ///
  /// The configured sources already stand in the reader's order. A source
  /// that only exists in old songs has no configuration any more; it goes to
  /// the end, named by the label the library still knows.
  List<String> _availableSources(
    LibraryState state,
    Map<String, SourceLabel> sourceLabels,
    List<MusicSourceConfig> configs,
  ) {
    final ids = state.songs.map((song) => song.sourceId ?? 'local').toSet();
    final ordered = <String>[
      for (final source in configs)
        if (ids.remove(source.id)) source.id,
    ];
    final leftovers = ids.toList()
      ..sort(
        (left, right) => compareText(
          sourceLabels[left]?.name ?? left,
          sourceLabels[right]?.name ?? right,
        ),
      );
    return [...ordered, ...leftovers];
  }

  Widget _body(
    LibraryState state,
    List<Song> songs,
    String? currentUri,
    bool isPlaying,
    Map<String, SourceLabel> sourceLabels,
    FavoritesState favorites,
    bool onlyLikeOnDoubleClick,
  ) {
    if (songs.isEmpty) {
      return LibraryEmptyState(
        state: state,
        onClearQuery: _clearQuery,
        onClearSourceFilter: () {
          ref.read(libraryControllerProvider.notifier).setSourceFilter(null);
        },
        onScan: _scan,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        0,
        CompactTokens.pageGutter,
        CompactTokens.space8,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return LibraryTrackCard(
          song: song,
          index: index,
          selected: song.uri == currentUri,
          playing: isPlaying,
          isFavorite: favorites.contains(song.uri),
          source: sourceLabel(song, sourceLabels),
          onTap: () {
            // The list the user clicks in decides what happens to the queue;
            // by default the track joins the queue and plays right away.
            ref.read(listPlaybackProvider).play(song);
          },
          onDoubleTap: () => _markFavorite(song),
          waitsForDoubleClick: onlyLikeOnDoubleClick,
          onAddToQueue: () => _addToQueue(song),
          onToggleFavorite: () => _toggleFavorite(song),
        );
      },
    );
  }

  void _addToQueue(Song song) {
    ref.read(playbackControllerProvider.notifier).addToQueue(song);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.libraryAddedToQueue),
          duration: Duration(milliseconds: 1200),
        ),
      );
  }

  /// Marks the track, or takes the mark away when it is already there.
  void _toggleFavorite(Song song) {
    ref.read(favoritesControllerProvider.notifier).toggle(song.uri);
  }

  /// A double click may add a mark, never take one away.
  void _markFavorite(Song song) {
    ref.read(favoritesControllerProvider.notifier).mark(song.uri);
  }

  /// Puts the whole visible list into the queue.
  void _addAllToQueue(List<Song> songs) {
    final added = ref
        .read(playbackControllerProvider.notifier)
        .addAllToQueue(songs);
    if (added == 0) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.libraryAddedToQueue),
          duration: Duration(milliseconds: 1200),
        ),
      );
  }

  void _clearQuery() {
    _searchController.clear();
    ref.read(libraryControllerProvider.notifier).setQuery('');
  }

  void _scan() {
    final settings = ref.read(settingsControllerProvider);
    ref
        .read(libraryControllerProvider.notifier)
        .scan(settings.effectiveScanPaths);
  }
}
