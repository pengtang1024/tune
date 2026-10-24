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
import 'package:tune/features/library/presentation/library_header.dart';
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
    // The page watches the tracks of the library and the state of the load.
    // A running scan reports its progress every percent, and the rows of
    // the list must not be rebuilt by it: the parts that show the scan watch
    // it on their own.
    final load = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.isLoading,
          value.hasValue,
          value.hasError,
          value.error,
        ),
      ),
    );
    final library = ref.watch(libraryControllerProvider.select(_librarySlice));
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

    if (load.$1 && !load.$2) {
      return const Center(child: CompactSpinner.large());
    }

    if (library == null) {
      return EmptyStateView(
        icon: Icons.error_outline_rounded,
        title: context.loc.libraryLoadFailedTitle,
        subtitle: '${load.$4 ?? context.loc.unknownError}',
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
    final availableSources = _availableSources(
      library,
      sourceLabels,
      sourceConfigs,
    );
    final songs = filteredSongsOf(
      songs: library.songs,
      query: library.query,
      sourceFilter: library.sourceFilter,
    );
    final albumCount = library.songs
        .map((song) => song.album.trim())
        .where((album) => album.isNotEmpty)
        .toSet()
        .length;
    final hasSourceIssues = library.sourceSummaries.values.any(
      (summary) => summary.status != SourceScanStatus.success,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            CompactTokens.space8,
            CompactTokens.pageGutter,
            CompactTokens.space4,
          ),
          child: LibraryHeader(
            summary: context.loc.librarySummary(
              library.songs.length,
              albumCount,
              availableSources.length,
            ),
            onAddAll: songs.isEmpty ? null : () => _addAllToQueue(songs),
            onSearchOnline: () => showOnlineSearchSheet(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            0,
            CompactTokens.pageGutter,
            CompactTokens.space8,
          ),
          child: LibraryToolbar(
            controller: _searchController,
            query: library.query,
            filteredCount: songs.length,
            sources: availableSources,
            sourceLabels: sourceLabels,
            sourceFilter: library.sourceFilter,
            onQueryChanged: (value) {
              ref.read(libraryControllerProvider.notifier).setQuery(value);
            },
            onClearQuery: _clearQuery,
            onSourceFilter: (value) {
              ref
                  .read(libraryControllerProvider.notifier)
                  .setSourceFilter(value);
            },
            onScan: _scan,
          ),
        ),
        LibraryScanStatusBar(sourceIssues: hasSourceIssues),
        Expanded(
          child: library.isLoading
              ? const Center(child: CompactSpinner.large())
              : _body(
                  library,
                  songs,
                  playback.$1,
                  playback.$2,
                  sourceLabels,
                  favorites,
                  settings.onlyLikeOnDoubleClick,
                ),
        ),
        if (library.songs.isEmpty)
          _LibraryPathsFooter(paths: settings.effectiveScanPaths),
      ],
    );
  }

  /// Sources that own at least one track of the library, in weight order.
  ///
  /// The configured sources already stand in the reader's order. A source
  /// that only exists in old songs has no configuration any more; it goes to
  /// the end, named by the label the library still knows.
  List<String> _availableSources(
    _LibrarySlice library,
    Map<String, SourceLabel> sourceLabels,
    List<MusicSourceConfig> configs,
  ) {
    final ids = library.songs.map((song) => song.sourceId ?? 'local').toSet();
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
    _LibrarySlice library,
    List<Song> songs,
    String? currentUri,
    bool isPlaying,
    Map<String, SourceLabel> sourceLabels,
    FavoritesState favorites,
    bool onlyLikeOnDoubleClick,
  ) {
    if (songs.isEmpty) {
      return LibraryEmptyState(
        query: library.query,
        hasSongs: library.songs.isNotEmpty,
        sourceFilter: library.sourceFilter,
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

/// The part of the library the page shows.
///
/// The scan of the sources is not part of it: a running scan reports its
/// progress every percent, and the rows of the list must not be rebuilt by
/// it. The parts that show the scan watch it on their own.
typedef _LibrarySlice = ({
  List<Song> songs,
  String query,
  String? sourceFilter,
  Map<String, SourceScanSummary> sourceSummaries,
  bool isLoading,
});

_LibrarySlice? _librarySlice(AsyncValue<LibraryState> value) {
  final state = value.valueOrNull;
  if (state == null) return null;
  return (
    songs: state.songs,
    query: state.query,
    sourceFilter: state.sourceFilter,
    sourceSummaries: state.sourceSummaries,
    isLoading: state.isLoading,
  );
}

/// The line that tells where the library is read from.
///
/// It only shows while the library is still empty, so it watches the scan on
/// its own: a running scan reports its progress every percent.
class _LibraryPathsFooter extends ConsumerWidget {
  final List<String> paths;

  const _LibraryPathsFooter({required this.paths});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.valueOrNull?.isScanning ?? false,
          value.valueOrNull?.errorMessage,
        ),
      ),
    );
    if (scan.$1 || scan.$2 != null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        0,
        CompactTokens.pageGutter,
        CompactTokens.space12,
      ),
      child: Text(
        context.loc.libraryScanPaths(paths.join('  ·  ')),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
