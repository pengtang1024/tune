import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/application/discovery_controller.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/discovery_state.dart';
import 'package:tune/features/discovery/presentation/daily_mix_card.dart';
import 'package:tune/features/discovery/presentation/discovery_actions.dart';
import 'package:tune/features/discovery/presentation/discovery_empty_views.dart';
import 'package:tune/features/discovery/presentation/discovery_header.dart';
import 'package:tune/features/discovery/presentation/discovery_info_sheet.dart';
import 'package:tune/features/discovery/presentation/discovery_section_view.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/compact_spinner.dart';

/// The discover page: a projection of the library and the hearts.
class DiscoveryPane extends ConsumerWidget {
  const DiscoveryPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(discoveryControllerProvider);
    final librarySongs = ref.watch(
      libraryControllerProvider.select(
        (value) => value.valueOrNull?.songs ?? const <Song>[],
      ),
    );
    final favorites = ref.watch(favoritesControllerProvider);
    final sources = ref.watch(
      musicSourcesControllerProvider.select(
        (value) => value.valueOrNull?.sources ?? const [],
      ),
    );
    final playback = ref.watch(
      playbackControllerProvider.select(
        (value) => (value.currentUri, value.isPlaying),
      ),
    );
    final onlyLike = ref.watch(
      settingsControllerProvider.select((value) => value.onlyLikeOnDoubleClick),
    );
    final useListening = ref.watch(
      settingsControllerProvider.select((value) => value.useListeningHistory),
    );
    final sourceLabels = sourceLabelsOf(context.loc, sources);
    final state = discovery.valueOrNull;
    final actions = DiscoveryActions(ref);

    return Column(
      children: [
        DiscoveryHeader(
          onRefresh: () =>
              ref.read(discoveryControllerProvider.notifier).refresh(),
          onInfo: () => showDiscoveryInfoSheet(context),
        ),
        if (librarySongs.isNotEmpty && favorites.ids.isEmpty)
          DiscoveryHint(
            icon: Icons.favorite_border_rounded,
            text: context.loc.discoverFavoriteHint,
          )
        else if (librarySongs.isNotEmpty && !useListening)
          DiscoveryHint(
            icon: Icons.history_rounded,
            text: context.loc.discoverHistoryHint,
            actionLabel: context.loc.discoverHistoryEnable,
            onAction: () => ref
                .read(settingsControllerProvider.notifier)
                .setUseListeningHistory(true),
          ),
        Expanded(
          child: _body(
            context,
            ref,
            discovery,
            state,
            librarySongs,
            favorites.ids,
            playback,
            onlyLike,
            sourceLabels,
            actions,
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DiscoveryState> discovery,
    DiscoveryState? state,
    List<Song> librarySongs,
    Set<String> favoriteUris,
    (String?, bool) playback,
    bool onlyLike,
    Map<String, SourceLabel> sourceLabels,
    DiscoveryActions actions,
  ) {
    if (state == null && discovery.isLoading) {
      return const Center(child: CompactSpinner.large());
    }
    if (state == null && discovery.hasError) {
      return discoveryFailure(
        context,
        () => ref.invalidate(discoveryControllerProvider),
      );
    }
    if (state == null) {
      return const Center(child: CompactSpinner.large());
    }
    if (state.isLoading) {
      return const Center(child: CompactSpinner.large());
    }
    if (state.failure != null) {
      return discoveryFailure(
        context,
        () => ref.invalidate(discoveryControllerProvider),
      );
    }

    if (state.sections.isEmpty) {
      if (librarySongs.isEmpty) return discoveryEmptyLibrary(context);
      return discoveryNoCandidates(
        context,
        () => actions.confirmClear(context),
      );
    }

    final children = <Widget>[];
    for (final section in state.sections) {
      if (section.kind == DiscoverySectionKind.dailyMix) {
        children.add(
          DailyMixCard(
            section: section,
            onPlay: () => actions.playSection(section),
            onAddAll: () => actions.addSection(context, section),
          ),
        );
      } else {
        children.add(
          DiscoverySectionView(
            section: section,
            sourceLabels: sourceLabels,
            favoriteUris: favoriteUris,
            currentUri: playback.$1,
            isPlaying: playback.$2,
            waitsForDoubleClick: onlyLike,
            onTap: actions.playSong,
            onDoubleTap: actions.doubleTap,
            onToggleFavorite: actions.toggleFavorite,
            onAddToQueue: (song) => actions.addToQueue(context, song),
            onDismiss: (song) => actions.dismiss(context, song),
            onDetails: (song) => actions.details(context, song, sourceLabels),
            onPlayAll: () => actions.playSection(section),
            onAddAll: () => actions.addSection(context, section),
          ),
        );
      }
      children.add(const SizedBox(height: CompactTokens.space20));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        0,
        CompactTokens.pageGutter,
        CompactTokens.space24,
      ),
      children: children,
    );
  }
}
