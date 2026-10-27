import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/utils/text_order.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/dead_songs_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_album.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_empty_state.dart';
import 'package:tune/features/library/presentation/library_album_header.dart';
import 'package:tune/features/library/presentation/library_albums_view.dart';
import 'package:tune/features/library/presentation/library_header.dart';
import 'package:tune/features/library/presentation/library_scan_status_bar.dart';
import 'package:tune/features/library/presentation/library_row_metrics.dart';
import 'package:tune/features/library/presentation/library_toolbar.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/search/presentation/online_search_sheet.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/application/source_health_reports.dart';
import 'package:tune/features/sources/domain/source_health.dart';
import 'package:tune/features/sources/domain/source_order.dart';
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

  /// The scroll positions of the two views.
  ///
  /// A view is disposed when the other one is shown; the controller keeps
  /// the place, so a reader who looked at an album and came back lands on
  /// the same covers instead of the top of the page.
  final ScrollController _songsScrollController = ScrollController();
  final ScrollController _albumsScrollController = ScrollController();

  /// How the list below the toolbar is read.
  LibraryViewMode _view = LibraryViewMode.songs;

  /// The album the reader opened, if any.
  ///
  /// The key is kept instead of the album itself: the album is grouped
  /// again on every build, and a search can take a track out of it.
  String? _openAlbumKey;

  /// The list widget of the last build, and what it was built from.
  ///
  /// The page rebuilds for its header and toolbar as well: a source changes
  /// its place, a scan finishes, the window loses focus. None of that changes
  /// a single row, and rebuilding the viewport for it costs about a third of
  /// a second. The list is handed back unchanged when every input a row
  /// paints is the same.
  Widget? _cachedTracks;
  List<Song>? _cachedTrackSongs;
  Map<String, SourceLabel>? _cachedTrackLabels;
  LibraryRowMetrics? _cachedTrackMetrics;

  /// Reads the next window when the reader reaches the end of the list.
  Widget _withLoadMore(Widget list, bool hasMore) {
    if (!hasMore) return list;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!mounted || _loadingMore) return false;
        if (notification.metrics.axis != Axis.vertical) return false;
        if (notification.metrics.extentAfter > 600) return false;
        _loadingMore = true;
        ref
            .read(libraryControllerProvider.notifier)
            .loadMore()
            .whenComplete(() {
              if (mounted) _loadingMore = false;
            });
        return false;
      },
      child: list,
    );
  }
  bool? _cachedTrackHasMore;

  /// Whether the next window of the library is already on its way.
  bool _loadingMore = false;
  bool? _cachedTrackWaits;
  ScrollController? _cachedTrackController;

  @override
  void dispose() {
    _searchController.dispose();
    _songsScrollController.dispose();
    _albumsScrollController.dispose();
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
        (value) =>
            (value.isLoading, value.hasValue, value.hasError, value.error),
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
    final sourceConfigs = ref.watch(
      musicSourcesControllerProvider.select(
        (value) => value.valueOrNull?.sources ?? const [],
      ),
    );
    // The page needs the order of the sources, not the whole health report:
    // a favorite changes the activity of a source without necessarily
    // changing its place, and the page must not rebuild for that.
    final sourceOrder = ref.watch(
      sourceHealthReportsProvider.select(
        (reports) => _sourceOrderKey(sourceConfigs, reports),
      ),
    );
    final orderedConfigs = _orderedSources(sourceConfigs, sourceOrder);
    final sourceLabels = sourceLabelsOf(context.loc, orderedConfigs);
    final availableSources = _availableSources(
      library,
      sourceLabels,
      orderedConfigs,
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
    // The albums are grouped only while the page is showing them: the songs
    // view has no use for the groups, and a library can hold thousands of
    // tracks.
    final albums = _view == LibraryViewMode.albums
        ? libraryAlbumsOf(songs)
        : const <LibraryAlbum>[];
    final openAlbum = _albumOfKey(albums);
    final hasSourceIssues = library.hasSourceIssues;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            CompactTokens.space8,
            CompactTokens.pageGutter,
            CompactTokens.space4,
          ),
          child: openAlbum == null
              ? LibraryHeader(
                  summary: context.loc.librarySummary(
                    library.songs.length,
                    albumCount,
                    availableSources.length,
                  ),
                  onAddAll: songs.isEmpty ? null : () => _addAllToQueue(songs),
                  onSearchOnline: () => showOnlineSearchSheet(context),
                  view: _view,
                  onViewChanged: _setView,
                )
              : LibraryAlbumHeader(
                  album: openAlbum,
                  onBack: () => setState(() => _openAlbumKey = null),
                  onPlay: () => _playAlbum(openAlbum),
                  onAddAll: () => _addAllToQueue(openAlbum.songs),
                ),
        ),
        if (openAlbum == null)
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
                  albums,
                  openAlbum,
                  sourceLabels,
                  settings.onlyLikeOnDoubleClick,
                ),
        ),
        if (library.songs.isEmpty)
          _LibraryPathsFooter(paths: settings.effectiveScanPaths),
      ],
    );
  }

  /// The order of the sources, as one value a `select` can compare.
  static String _sourceOrderKey(
    List<MusicSourceConfig> configs,
    Map<String, SourceHealthReport> health,
  ) {
    return [
      for (final source in orderSourcesByBand(configs, health)) source.id,
    ].join('\u0000');
  }

  /// Puts the configured sources back into the order of [key].
  static List<MusicSourceConfig> _orderedSources(
    List<MusicSourceConfig> configs,
    String key,
  ) {
    final byId = {for (final config in configs) config.id: config};
    return [for (final id in key.split('\u0000')) ?byId[id]];
  }

  /// Sources that own at least one track of the library, in health band and
  /// weight order.
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
    List<LibraryAlbum> albums,
    LibraryAlbum? openAlbum,
    Map<String, SourceLabel> sourceLabels,
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

    if (openAlbum != null) {
      return _trackList(openAlbum.songs, sourceLabels, onlyLikeOnDoubleClick);
    }

    if (_view == LibraryViewMode.albums) {
      // The album grid is the only place that needs to know which album
      // plays. Listening here keeps a change of track from rebuilding the
      // page and its list.
      return Consumer(
        builder: (context, ref, child) {
          final currentUri = ref.watch(
            playbackControllerProvider.select(
              (value) => value.currentSong?.uri,
            ),
          );
          return LibraryAlbumsView(
            albums: albums,
            currentAlbumKey: _currentAlbumKey(library.songs, currentUri),
            controller: _albumsScrollController,
            onOpen: (album) => setState(() => _openAlbumKey = album.key),
            onPlay: _playAlbum,
          );
        },
      );
    }

    return _trackList(
      songs,
      sourceLabels,
      onlyLikeOnDoubleClick,
      controller: _songsScrollController,
      hasMore:
          library.hasMore && library.query.isEmpty && library.sourceFilter == null,
    );
  }

  Widget _trackList(
    List<Song> songs,
    Map<String, SourceLabel> sourceLabels,
    bool onlyLikeOnDoubleClick, {
    ScrollController? controller,
    bool hasMore = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The width of a row is the width of the list without its gutter.
        // It is resolved once here, so a row does not run a layout callback
        // of its own to discover the same number.
        final metrics = LibraryRowMetrics.of(
          context,
          constraints.maxWidth - CompactTokens.pageGutter * 2,
        );

        final cached = _cachedTracks;
        if (cached != null &&
            identical(controller, _cachedTrackController) &&
            onlyLikeOnDoubleClick == _cachedTrackWaits &&
            metrics == _cachedTrackMetrics &&
            hasMore == _cachedTrackHasMore &&
            _sameRows(_cachedTrackSongs!, songs) &&
            mapEquals(_cachedTrackLabels!, sourceLabels)) {
          return cached;
        }

        final list = ListView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            0,
            CompactTokens.pageGutter,
            CompactTokens.space8,
          ),
          itemExtent: metrics.extent,
          // A row holds no state worth keeping alive: its timers die with
          // it and the mark comes back from the controller. The default
          // wrapper only adds a listener to every row.
          addAutomaticKeepAlives: false,
          itemCount: songs.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= songs.length) {
              return Center(
                child: TextButton.icon(
                  key: const ValueKey('library-load-more'),
                  onPressed: () => ref
                      .read(libraryControllerProvider.notifier)
                      .loadMore(),
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    size: CompactTokens.icon16,
                  ),
                  label: Text(context.loc.libraryLoadMore),
                ),
              );
            }
            final song = songs[index];
            // Each row listens to the three values it paints, not to the
            // whole page state. Liking a track rebuilds one row; playing a
            // track rebuilds the two rows whose mark changes.
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
                return LibraryTrackCard(
                  song: song,
                  index: index,
                  selected: selected,
                  playing: playing,
                  isFavorite: isFavorite,
                  unavailable: ref.watch(deadSongsProvider).contains(song.uri),
                  source: sourceLabel(song, sourceLabels),
                  metrics: metrics,
                  onTap: () {
                    // The list the user clicks in decides what happens to
                    // the queue; by default the track joins the queue and
                    // plays right away.
                    ref.read(listPlaybackProvider).play(song);
                  },
                  onDoubleTap: () => _markFavorite(song),
                  waitsForDoubleClick: onlyLikeOnDoubleClick,
                  onAddToQueue: () => _addToQueue(song),
                  onToggleFavorite: () => _toggleFavorite(song),
                );
              },
            );
          },
        );
        _cachedTrackSongs = songs;
        _cachedTrackLabels = sourceLabels;
        _cachedTrackMetrics = metrics;
        _cachedTrackHasMore = hasMore;
        _cachedTrackWaits = onlyLikeOnDoubleClick;
        _cachedTrackController = controller;
        return _cachedTracks = _withLoadMore(list, hasMore);
      },
    );
  }

  /// Whether two rows lists hold the same tracks in the same order.
  static bool _sameRows(List<Song> left, List<Song> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (!identical(left[i], right[i])) return false;
    }
    return true;
  }

  /// The key of the album that holds the track that plays.
  ///
  /// The grid marks the album the reader is hearing; the track may be
  /// outside the current search, so the key is looked up in the whole
  /// library and not only in the list on screen.
  String? _currentAlbumKey(List<Song> librarySongs, String? currentUri) {
    if (currentUri == null) return null;
    for (final song in librarySongs) {
      if (song.uri == currentUri) return libraryAlbumKeyOf(song);
    }
    return null;
  }

  /// The album of [_openAlbumKey] in the albums that are on screen now.
  LibraryAlbum? _albumOfKey(List<LibraryAlbum> albums) {
    final key = _openAlbumKey;
    if (key == null) return null;
    for (final album in albums) {
      if (album.key == key) return album;
    }
    return null;
  }

  void _setView(LibraryViewMode view) {
    setState(() {
      _view = view;
      _openAlbumKey = null;
    });
  }

  Future<void> _playAlbum(LibraryAlbum album) async {
    if (album.songs.isEmpty) return;
    await ref.read(playbackControllerProvider.notifier).playQueue(album.songs);
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
  bool hasSourceIssues,
  bool isLoading,
  bool hasMore,
});

_LibrarySlice? _librarySlice(AsyncValue<LibraryState> value) {
  final state = value.valueOrNull;
  if (state == null) return null;
  return (
    songs: state.songs,
    query: state.query,
    sourceFilter: state.sourceFilter,
    // The page only shows whether a source has a problem, not the whole
    // report: a scan that finishes without changing the songs must not hand
    // the page a new map and rebuild every visible row for it.
    hasSourceIssues: state.sourceSummaries.values.any(
      (summary) => summary.status != SourceScanStatus.success,
    ),
    isLoading: state.isLoading,
    hasMore: state.hasMore,
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
