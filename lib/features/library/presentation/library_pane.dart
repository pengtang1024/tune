import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_empty_state.dart';
import 'package:tune/features/library/presentation/library_scan_status_bar.dart';
import 'package:tune/features/library/presentation/library_toolbar.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/search/presentation/online_search_sheet.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
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
      return const Center(child: CircularProgressIndicator());
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
    final playback = ref.watch(
      playbackControllerProvider.select(
        (value) => (value.currentSong?.uri, value.isPlaying),
      ),
    );
    final sourceNames = ref.watch(musicSourceNamesProvider);
    final songs = state.filteredSongs;
    final hasSourceIssues = state.sourceSummaries.values.any(
      (summary) => summary.status != SourceScanStatus.success,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 14),
          child: PageHeading(
            eyebrow: 'COLLECTION',
            title: context.loc.libraryTitle,
            subtitle: context.loc.librarySubtitle,
            trailing: OutlinedButton.icon(
              onPressed: () => showOnlineSearchSheet(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(
                  horizontal: CompactTokens.space12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              icon: const Icon(Icons.travel_explore_rounded, size: 16),
              label: Text(context.loc.searchOnlineTitle),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
          child: LibraryToolbar(
            controller: _searchController,
            query: state.query,
            filteredCount: songs.length,
            sources: _availableSources(state, sourceNames),
            sourceNames: sourceNames,
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
              ? const Center(child: CircularProgressIndicator())
              : _body(state, songs, playback.$1, playback.$2, sourceNames),
        ),
        if (!state.hasSongs && !state.isScanning && state.errorMessage == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CompactTokens.space16,
              0,
              CompactTokens.space16,
              CompactTokens.space12,
            ),
            child: Text(
              context.loc.libraryScanPaths(
                settings.effectiveScanPaths.join('  ·  '),
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// Sources that own at least one track of the library.
  List<String> _availableSources(
    LibraryState state,
    Map<String, String> sourceNames,
  ) {
    final sources =
        state.songs
            .map((song) => song.sourceId ?? 'local')
            .toSet()
            .toList(growable: false)
          ..sort(
            (a, b) => (sourceNames[a] ?? a).compareTo(sourceNames[b] ?? b),
          );
    return sources;
  }

  Widget _body(
    LibraryState state,
    List<Song> songs,
    String? currentUri,
    bool isPlaying,
    Map<String, String> sourceNames,
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
      padding: const EdgeInsets.fromLTRB(28, 0, 28, CompactTokens.space8),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return LibraryTrackCard(
          song: song,
          index: index,
          selected: song.uri == currentUri,
          playing: isPlaying,
          sourceName: sourceLabel(song, sourceNames),
          onTap: () {
            ref
                .read(playbackControllerProvider.notifier)
                .playQueue(songs, startIndex: index);
          },
          onAddToQueue: () => _addToQueue(song),
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
