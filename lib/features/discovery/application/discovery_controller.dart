import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/application/discovery_providers.dart';
import 'package:tune/features/discovery/data/discovery_feedback_store.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/discovery_state.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommended_track.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';
import 'package:tune/features/discovery/domain/taste_aggregates.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/application/source_health_scores.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/utils/logger.dart';

typedef _LibrarySnapshot = ({
  bool isLoading,
  bool hasValue,
  bool hasError,
  List<Song> songs,
  int total,
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
  DiscoveryArtistFeedbackStore? _artistFeedbackStore;
  Map<String, DateTime> _feedback = const {};
  Map<String, DateTime> _artistFeedback = const {};
  bool _artistFeedbackLoaded = false;
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
    _artistFeedbackStore = ref.watch(discoveryArtistFeedbackStoreProvider);
    if (!_artistFeedbackLoaded) {
      _artistFeedback = _artistFeedbackStore!.read();
      _artistFeedbackLoaded = true;
    }

    final library = ref.watch(libraryControllerProvider.select(_snapshotOf));
    final favoriteUris = ref.watch(
      favoritesControllerProvider.select((state) => state.ids),
    );
    final sourceOrderKey = ref.watch(
      musicSourcesControllerProvider.select(_sourceOrderKeyOf),
    );
    final queue = ref.watch(
      playbackControllerProvider.select((state) => state.queue),
    );
    final sourceHealth = ref.watch(sourceHealthScoresProvider);
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
      queuedUris: {for (final song in queue) song.uri},
      sourceHealth: sourceHealth,
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
    await _recompute();
  }

  /// Takes one mark away, for example when the reader undoes a dismissal.
  Future<void> forgetDismissal(String uri) async {
    if (!_feedback.containsKey(uri)) return;
    _feedback = {..._feedback}..remove(uri);
    await _feedbackStore?.write(_feedback);
    await _recompute();
  }

  /// Shows less of a whole artist for the same thirty days.
  Future<void> dismissArtist(String artist) async {
    final key = normalizeTasteKey(artist);
    if (key.isEmpty) return;
    if (_artistFeedback.containsKey(key)) return;
    _artistFeedback = {..._artistFeedback, key: DateTime.now()};
    await _artistFeedbackStore?.dismiss(key);
    await _recompute();
  }

  Future<void> forgetArtistDismissal(String artist) async {
    final key = normalizeTasteKey(artist);
    if (!_artistFeedback.containsKey(key)) return;
    _artistFeedback = {..._artistFeedback}..remove(key);
    await _artistFeedbackStore?.remove(key);
    await _recompute();
  }

  /// Removes every mark and every listen the page kept.
  Future<void> clearFeedback() async {
    _feedback = const {};
    _artistFeedback = const {};
    _listening = const {};
    _onlineSections.clear();
    await _feedbackStore?.clear();
    await _artistFeedbackStore?.clear();
    await ref.read(listeningSignalStoreProvider).clear();
    await _recompute();
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
      if (!_disposed) await _recompute();
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

  Future<void> _recompute() async {
    if (_disposed) return;
    _refreshListening();
    final next = await _compute(
      library: _snapshotOf(ref.read(libraryControllerProvider)),
      favoriteUris: ref.read(favoritesControllerProvider).ids,
      sourceOrder: _sourceOrderOf(
        _sourceOrderKeyOf(ref.read(musicSourcesControllerProvider)),
      ),
      queuedUris: {
        for (final song in ref.read(playbackControllerProvider).queue)
          song.uri,
      },
      sourceHealth: ref.read(sourceHealthScoresProvider),
    );
    if (_disposed) return;
    state = AsyncData(next);
  }

  Future<DiscoveryState> _compute({
    required _LibrarySnapshot library,
    required Set<String> favoriteUris,
    required List<String> sourceOrder,
    required Set<String> queuedUris,
    required Map<String, double> sourceHealth,
  }) async {
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
      // A library larger than the window is counted by the database; the
      // tracks on the page still come from the window, but the taste of the
      // reader is read from every track that was ever stored.
      final profile = library.total > songs.length
          ? _profileFromAggregates(
              await ref.read(libraryStorageProvider).tasteAggregates(),
              now: now,
              favoriteCount: favoriteUris.length,
            )
          : TasteProfile.from(
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
            dismissedArtists: _artistFeedback.keys.toSet(),
            queuedUris: queuedUris,
            sourceHealth: sourceHealth,
            listening: _listening,
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

  /// Builds the profile from the counts the database already grouped.
  TasteProfile _profileFromAggregates(
    TasteAggregates aggregates, {
    required DateTime now,
    required int favoriteCount,
  }) {
    final artists = <String, double>{};
    final genres = <String, double>{};
    final decades = <int, double>{};
    final albums = <String, double>{};

    for (final entry in aggregates.artists.entries) {
      final key = normalizeTasteKey(entry.key);
      if (key.isEmpty || isGenericArtistKey(key)) continue;
      artists.update(
        key,
        (value) => value + entry.value * 3,
        ifAbsent: () => entry.value * 3,
      );
    }
    for (final entry in aggregates.genres.entries) {
      final key = normalizeTasteKey(entry.key);
      if (key.isEmpty || isGenericGenreKey(key)) continue;
      genres.update(
        key,
        (value) => value + entry.value * 1.5,
        ifAbsent: () => entry.value * 1.5,
      );
    }
    for (final entry in aggregates.albums.entries) {
      final key = normalizeTasteKey(entry.key);
      if (key.isEmpty) continue;
      albums.update(
        key,
        (value) => value + entry.value.toDouble(),
        ifAbsent: () => entry.value.toDouble(),
      );
    }
    for (final entry in aggregates.decades.entries) {
      decades.update(
        entry.key,
        (value) => value + entry.value.toDouble(),
        ifAbsent: () => entry.value.toDouble(),
      );
    }

    var listenCount = 0;
    for (final row in aggregates.signals) {
      final weight = listenWeight(row.signal, now);
      listenCount += row.signal.listens;
      if (weight <= 0) continue;

      final artist = normalizeTasteKey(row.artist);
      if (artist.isNotEmpty && !isGenericArtistKey(artist)) {
        artists.update(artist, (value) => value + weight, ifAbsent: () => weight);
      }
      final genre = normalizeTasteKey(row.genre);
      if (genre.isNotEmpty && !isGenericGenreKey(genre)) {
        genres.update(
          genre,
          (value) => value + weight * 0.5,
          ifAbsent: () => weight * 0.5,
        );
      }
      final decade = decadeOf(row.year);
      if (decade != null) {
        decades.update(
          decade,
          (value) => value + weight * 0.5,
          ifAbsent: () => weight * 0.5,
        );
      }
      final album = normalizeTasteKey(row.album);
      if (album.isNotEmpty) {
        albums.update(
          album,
          (value) => value + weight * 0.3,
          ifAbsent: () => weight * 0.3,
        );
      }
    }

    return TasteProfile.fromWeights(
      artists: artists,
      genres: genres,
      decades: decades,
      albums: albums,
      favoriteCount: favoriteCount,
      listenCount: listenCount,
    );
  }

  static _LibrarySnapshot _snapshotOf(AsyncValue<LibraryState> value) {
    return (
      isLoading: value.isLoading,
      hasValue: value.hasValue,
      hasError: value.hasError,
      songs: value.valueOrNull?.songs ?? const <Song>[],
      total: value.valueOrNull?.total ?? 0,
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
