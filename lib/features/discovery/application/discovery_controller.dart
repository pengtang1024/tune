import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/application/discovery_providers.dart';
import 'package:tune/features/discovery/data/discovery_feedback_store.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/discovery_state.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommended_track.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/utils/logger.dart';

typedef _LibrarySnapshot = ({
  bool isLoading,
  bool hasValue,
  bool hasError,
  List<Song> songs,
});

final discoveryControllerProvider =
    AutoDisposeAsyncNotifierProvider<DiscoveryController, DiscoveryState>(
      DiscoveryController.new,
    );

/// Owns the page the discover tab shows.
///
/// The sections are a projection of the library, the hearts and the feedback
/// store. They are not a second copy of any of those: a change in the inputs
/// rebuilds the projection, and leaving the page drops it.
class DiscoveryController extends AutoDisposeAsyncNotifier<DiscoveryState> {
  DiscoveryFeedbackStore? _feedbackStore;
  Map<String, DateTime> _feedback = const {};
  Map<String, TrackListening> _listening = const {};
  final List<DiscoverySection> _onlineSections = [];
  Set<String> _finding = const {};
  bool _feedbackLoaded = false;
  int _salt = 0;
  bool _disposed = false;

  @override
  Future<DiscoveryState> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    _feedbackStore = ref.watch(discoveryFeedbackStoreProvider);
    if (!_feedbackLoaded) {
      _feedback = _feedbackStore!.read();
      _feedbackLoaded = true;
    }

    final library = ref.watch(libraryControllerProvider.select(_snapshotOf));
    final favoriteUris = ref.watch(
      favoritesControllerProvider.select((state) => state.ids),
    );
    final sourceOrderKey = ref.watch(
      musicSourcesControllerProvider.select(_sourceOrderKeyOf),
    );
    final useListening = ref.watch(
      settingsControllerProvider.select((state) => state.useListeningHistory),
    );
    _listening = useListening
        ? ref.read(listeningSignalStoreProvider).read()
        : const {};

    return _compute(
      library: library,
      favoriteUris: favoriteUris,
      sourceOrder: _sourceOrderOf(sourceOrderKey),
    );
  }

  /// Builds the page again with a new session salt.
  ///
  /// The salt lives only while the page is open: leaving the page and coming
  /// back shows the stable mix of the day again.
  void refresh() {
    _salt++;
    _onlineSections.clear();
    _refreshListening();
    _recompute();
  }

  /// Marks a track as not interesting and builds the page again.
  Future<void> dismiss(String uri) async {
    if (uri.isEmpty) return;
    final now = DateTime.now();
    _feedback = {
      for (final entry in _feedback.entries)
        if (now.difference(entry.value) < DiscoveryFeedbackStore.ttl)
          entry.key: entry.value,
      uri: now,
    };
    await _feedbackStore?.write(_feedback);
    _recompute();
  }

  /// Takes one mark away, for example when the reader undoes a dismissal.
  Future<void> forgetDismissal(String uri) async {
    if (!_feedback.containsKey(uri)) return;
    _feedback = {..._feedback}..remove(uri);
    await _feedbackStore?.write(_feedback);
    _recompute();
  }

  /// Removes every mark and every listen the page kept.
  Future<void> clearFeedback() async {
    _feedback = const {};
    _listening = const {};
    _onlineSections.clear();
    await _feedbackStore?.clear();
    await ref.read(listeningSignalStoreProvider).clear();
    _recompute();
  }

  /// Looks for more tracks of [artist] in the enabled online sources.
  ///
  /// Nothing is fetched until the reader presses the button. The results are
  /// kept in memory for this visit only; they never enter the library.
  Future<DiscoveryOnlineResult> findMoreByArtist(String rawArtist) async {
    final artist = rawArtist.trim();
    if (artist.isEmpty) return DiscoveryOnlineResult.noResults;
    if (_finding.contains(artist)) return DiscoveryOnlineResult.added;
    _setFinding({..._finding, artist});

    try {
      final sources =
          ref.read(musicSourcesControllerProvider).valueOrNull?.sources ??
          const [];
      final remote = sources
          .where((source) => source.enabled && !source.isLocal)
          .toList(growable: false);
      if (remote.isEmpty) return DiscoveryOnlineResult.noSources;

      final results = await ref
          .read(musicSourceServiceProvider)
          .search(sources: remote, query: artist);
      if (_disposed) return DiscoveryOnlineResult.noResults;

      final known = {
        for (final song
            in ref.read(libraryControllerProvider).valueOrNull?.songs ??
                const <Song>[])
          song.uri,
      };
      final key = normalizeTasteKey(artist);
      final seen = <String>{};
      final tracks = <RecommendedTrack>[];
      for (final result in results) {
        if (!result.isSuccess) continue;
        for (final song in result.songs) {
          if (song.uri.isEmpty || song.isLiveStream) continue;
          if (known.contains(song.uri) || !seen.add(song.uri)) continue;
          if (!_matchesArtist(song, key)) continue;
          tracks.add(
            RecommendedTrack(
              song: song,
              score: 0,
              reason: RecommendationReason(
                kind: RecommendationReasonKind.artist,
                artist: artist,
                confidence: 1,
              ),
              fromFavorites: false,
            ),
          );
          if (tracks.length >= 20) break;
        }
        if (tracks.length >= 20) break;
      }
      if (tracks.isEmpty) return DiscoveryOnlineResult.noResults;

      final online = DiscoverySection(
        kind: DiscoverySectionKind.onlineArtist,
        reason: RecommendationReason(
          kind: RecommendationReasonKind.artist,
          artist: artist,
          confidence: 1,
        ),
        tracks: List.unmodifiable(tracks),
      );
      _onlineSections.removeWhere(
        (section) => normalizeTasteKey(section.reason.artist ?? '') == key,
      );
      _onlineSections.add(online);
      return DiscoveryOnlineResult.added;
    } catch (error, stackTrace) {
      Log.error('在线查找歌手失败: $error\n$stackTrace');
      return DiscoveryOnlineResult.failed;
    } finally {
      _setFinding({..._finding}..remove(artist));
      if (!_disposed) _recompute();
    }
  }

  bool _matchesArtist(Song song, String key) {
    if (key.isEmpty) return true;
    final artist = normalizeTasteKey(song.artist);
    if (artist.isEmpty) return false;
    return artist.contains(key) || key.contains(artist);
  }

  void _setFinding(Set<String> next) {
    _finding = Set.unmodifiable(next);
    final current = state.valueOrNull;
    if (current != null && !_disposed) {
      state = AsyncData(current.copyWith(findingArtists: _finding));
    }
  }

  void _refreshListening() {
    final enabled = ref.read(settingsControllerProvider).useListeningHistory;
    _listening = enabled
        ? ref.read(listeningSignalStoreProvider).read()
        : const {};
  }

  void _recompute() {
    if (_disposed) return;
    _refreshListening();
    state = AsyncData(
      _compute(
        library: _snapshotOf(ref.read(libraryControllerProvider)),
        favoriteUris: ref.read(favoritesControllerProvider).ids,
        sourceOrder: _sourceOrderOf(
          _sourceOrderKeyOf(ref.read(musicSourcesControllerProvider)),
        ),
      ),
    );
  }

  DiscoveryState _compute({
    required _LibrarySnapshot library,
    required Set<String> favoriteUris,
    required List<String> sourceOrder,
  }) {
    if (library.isLoading && !library.hasValue) {
      return const DiscoveryState(isLoading: true);
    }
    if (library.hasError && !library.hasValue) {
      return const DiscoveryState(failure: DiscoveryFailure.libraryUnavailable);
    }

    final now = DateTime.now();
    final dateKey = _dateKey(now);
    final songs = library.songs;
    if (songs.isEmpty) {
      return DiscoveryState(
        generatedAt: now,
        dateKey: dateKey,
        findingArtists: _finding,
      );
    }

    try {
      final profile = TasteProfile.from(
        library: songs,
        favoriteUris: favoriteUris,
        listening: _listening,
        now: now,
      );
      final output = ref
          .read(recommendationEngineProvider)
          .recommend(
            library: songs,
            favoriteUris: favoriteUris,
            profile: profile,
            dismissedUris: _feedback.keys.toSet(),
            sourceOrder: sourceOrder,
            dateKey: dateKey,
            refreshSalt: _salt,
            allowFresh: true,
            now: now,
          );
      return DiscoveryState(
        sections: List.unmodifiable([
          ...output.sections,
          ..._visibleOnlineSections(),
        ]),
        generatedAt: now,
        dateKey: dateKey,
        findingArtists: _finding,
      );
    } catch (error, stackTrace) {
      Log.error('计算推荐失败: $error\n$stackTrace');
      return DiscoveryState(
        failure: DiscoveryFailure.computationFailed,
        generatedAt: now,
        dateKey: dateKey,
      );
    }
  }

  List<DiscoverySection> _visibleOnlineSections() {
    final visible = <DiscoverySection>[];
    for (final section in _onlineSections) {
      final tracks = [
        for (final track in section.tracks)
          if (!_feedback.containsKey(track.song.uri)) track,
      ];
      if (tracks.isEmpty) continue;
      visible.add(
        DiscoverySection(
          kind: section.kind,
          reason: section.reason,
          tracks: List.unmodifiable(tracks),
        ),
      );
    }
    return visible;
  }

  static _LibrarySnapshot _snapshotOf(AsyncValue<LibraryState> value) {
    return (
      isLoading: value.isLoading,
      hasValue: value.hasValue,
      hasError: value.hasError,
      songs: value.valueOrNull?.songs ?? const <Song>[],
    );
  }

  static String _sourceOrderKeyOf(AsyncValue<MusicSourcesState> value) {
    final list = value.valueOrNull?.sources;
    if (list == null || list.isEmpty) return '';
    return list.map((source) => source.id).join('\u0000');
  }

  static List<String> _sourceOrderOf(String key) {
    if (key.isEmpty) return const [];
    return List<String>.unmodifiable(key.split('\u0000'));
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
