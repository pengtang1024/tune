import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/favorites/domain/favorites_state.dart';
import 'package:tune/features/favorites/presentation/favorites_track_row.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/empty_state_view.dart';
import 'package:tune/shared/ui/page_heading.dart';
import 'package:tune/shared/ui/source_label.dart';

/// The page that holds the tracks the user marked with a heart.
///
/// The page is a view of the library: a favorite is a track of the library
/// the user kept, so the page names the tracks the library knows and the
/// controller says which of them are marked.
class FavoritesPane extends ConsumerStatefulWidget {
  const FavoritesPane({super.key});

  @override
  ConsumerState<FavoritesPane> createState() => _FavoritesPaneState();
}

class _FavoritesPaneState extends ConsumerState<FavoritesPane> {
  Timer? _clickGuard;
  bool _ignoreClicks = false;

  @override
  void dispose() {
    _clickGuard?.cancel();
    super.dispose();
  }

  /// Blocks the second click of a double click on a heart.
  ///
  /// Taking a mark away removes the row, so the next row slides under the
  /// pointer. Without this guard the second click would take the mark of the
  /// next track instead of being part of the same gesture.
  void _guardClicks() {
    _clickGuard?.cancel();
    if (!_ignoreClicks) setState(() => _ignoreClicks = true);
    _clickGuard = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _ignoreClicks = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryControllerProvider);
    final favorites = ref.watch(favoritesControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final playback = ref.watch(
      playbackControllerProvider.select(
        (value) => (value.currentSong?.uri, value.isPlaying),
      ),
    );
    final sourceLabels = sourceLabelsOf(
      context.loc,
      ref.watch(
        musicSourcesControllerProvider.select(
          (value) => value.valueOrNull?.sources ?? const [],
        ),
      ),
    );

    final songs = _markedSongs(
      library.valueOrNull?.songs ?? const [],
      favorites,
    );

    // The marks the library cannot name: a track that was marked from the
    // online search and never scanned, or a track whose source is off now.
    // The marks are kept, so the page has to say that they are not here.
    // A library that did not load yet knows no track at all, so it may not
    // say that the marks are outside of it.
    final outside = library.hasValue ? favorites.count - songs.length : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            CompactTokens.pageTopPadding,
            CompactTokens.pageGutter,
            CompactTokens.pageHeadingGap,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeading(
                // Favorites are a collection of their own, so the page
                // names that section instead of borrowing the library's.
                eyebrow: context.loc.favoritesEyebrow,
                title: context.loc.favoritesTitle,
                subtitle: context.loc.favoritesSubtitle,
                trailing: Text(
                  context.loc.libraryTrackCount(favorites.count),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (outside > 0) ...[
                const SizedBox(height: CompactTokens.space8),
                _OutsideNote(count: outside),
              ],
            ],
          ),
        ),
        Expanded(
          child: _body(
            context,
            ref,
            library,
            songs,
            favorites,
            playback,
            sourceLabels,
            settings.favoritesDoubleClickPlays,
          ),
        ),
      ],
    );
  }

  /// The tracks of the library that are marked.
  List<Song> _markedSongs(List<Song> songs, FavoritesState favorites) {
    return songs
        .where((song) => favorites.contains(song.uri))
        .toList(growable: false);
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<LibraryState> library,
    List<Song> songs,
    FavoritesState favorites,
    (String?, bool) playback,
    Map<String, SourceLabel> sourceLabels,
    bool favoritesDoubleClickPlays,
  ) {
    if (library.isLoading && !library.hasValue) {
      return const Center(child: CompactSpinner.large());
    }

    if (library.hasError && !library.hasValue) {
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

    if (songs.isEmpty) {
      // An empty page with marks in the store is not an empty collection:
      // the library simply does not hold the tracks that were marked.
      final markedOutside = favorites.count > 0;

      return EmptyStateView(
        icon: markedOutside
            ? Icons.help_outline_rounded
            : Icons.favorite_border_rounded,
        title: markedOutside
            ? context.loc.favoritesEmptyOutsideTitle
            : context.loc.favoritesEmptyTitle,
        subtitle: markedOutside
            ? context.loc.favoritesEmptyOutsideSubtitle
            : context.loc.favoritesEmptySubtitle,
        action: FilledButton(
          onPressed: () => context.go('/library'),
          child: Text(context.loc.favoritesGoToLibrary),
        ),
      );
    }

    return IgnorePointer(
      ignoring: _ignoreClicks,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.pageGutter,
          0,
          CompactTokens.pageGutter,
          CompactTokens.space8,
        ),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return FavoritesTrackRow(
            key: ValueKey(song.uri),
            song: song,
            index: index,
            selected: song.uri == playback.$1,
            playing: playback.$2,
            source: sourceLabel(song, sourceLabels),
            onTap: () {
              // The list the user clicks in decides what happens to the queue;
              // by default the track joins the queue and plays right away.
              ref.read(listPlaybackProvider).play(song);
            },
            onDoubleTap: () {
              if (favoritesDoubleClickPlays) {
                unawaited(
                  ref.read(playbackControllerProvider.notifier).playSong(song),
                );
                return;
              }
              _markFavorite(ref, song);
            },
            // A double click in this list has its own action; the click
            // waits so the first half of it does not play or enqueue.
            waitsForDoubleClick: true,
            onToggleFavorite: () => _toggleFavorite(ref, song),
          );
        },
      ),
    );
  }

  /// Marks the track, or takes the mark away when it is already there.
  void _toggleFavorite(WidgetRef ref, Song song) {
    ref.read(favoritesControllerProvider.notifier).toggle(song.uri);
    // A double click on the heart must not reach the row that slides up.
    _guardClicks();
  }

  /// A double click adds a mark; it never takes one away.
  void _markFavorite(WidgetRef ref, Song song) {
    ref.read(favoritesControllerProvider.notifier).mark(song.uri);
  }
}

/// The line that says how many marks the library cannot name.
class _OutsideNote extends StatelessWidget {
  final int count;

  const _OutsideNote({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: CompactTokens.icon16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: CompactTokens.space8),
        Expanded(
          child: Text(
            context.loc.favoritesOutsideLibrary(count),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
