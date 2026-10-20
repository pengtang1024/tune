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
class FavoritesPane extends ConsumerWidget {
  const FavoritesPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // The favorites belong to the collection, so the page names the
            // same section as the library instead of repeating its own.
            eyebrow: context.loc.libraryEyebrow,
            title: context.loc.favoritesTitle,
            subtitle: context.loc.favoritesSubtitle,
            trailing: Text(
              context.loc.libraryTrackCount(songs.length),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: _body(
            context,
            ref,
            library,
            songs,
            playback,
            sourceLabels,
            settings.onlyLikeOnDoubleClick,
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
    (String?, bool) playback,
    Map<String, SourceLabel> sourceLabels,
    bool onlyLikeOnDoubleClick,
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
      return EmptyStateView(
        icon: Icons.favorite_border_rounded,
        title: context.loc.favoritesEmptyTitle,
        subtitle: context.loc.favoritesEmptySubtitle,
        action: FilledButton(
          onPressed: () => context.go('/library'),
          child: Text(context.loc.favoritesGoToLibrary),
        ),
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
          onDoubleTap: () => _toggleFavorite(ref, song),
          waitsForDoubleClick: onlyLikeOnDoubleClick,
          onToggleFavorite: () => _toggleFavorite(ref, song),
        );
      },
    );
  }

  /// Marks the track, or takes the mark away when it is already there.
  void _toggleFavorite(WidgetRef ref, Song song) {
    ref.read(favoritesControllerProvider.notifier).toggle(song.uri);
  }
}
