import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/application/discovery_providers.dart';
import 'package:tune/features/discovery/data/discovery_feedback_store.dart';
import 'package:tune/features/discovery/domain/discovery_state.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
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
    await _feedbackStore?.clear();
    await ref.read(listeningSignalStoreProvider).clear();
    _recompute();
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
      return DiscoveryState(generatedAt: now, dateKey: dateKey);
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
        sections: output.sections,
        generatedAt: now,
        dateKey: dateKey,
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
