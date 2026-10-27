import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/library/data/dead_song_store.dart';
import 'package:tune/providers/persistence_providers.dart';

/// The tracks whose playback failed, by their canonical URI.
///
/// A failed track stays in the library; the mark only tells the reader that
/// the last attempt did not play. A successful play takes the mark away.
final deadSongsProvider =
    StateNotifierProvider<DeadSongsController, Set<String>>((ref) {
      final store = DeadSongStore(ref.watch(persistenceServiceProvider));
      return DeadSongsController(store);
    });

class DeadSongsController extends StateNotifier<Set<String>> {
  DeadSongsController(this._store) : super(_store.read());

  final DeadSongStore _store;

  /// Marks a track whose playback failed.
  Future<void> markFailed(String uri) async {
    if (uri.isEmpty || state.contains(uri)) return;
    final next = {...state, uri};
    state = next;
    await _store.write(next);
  }

  /// Takes the mark away when the track plays again.
  Future<void> clear(String uri) async {
    if (uri.isEmpty || !state.contains(uri)) return;
    final next = {...state}..remove(uri);
    state = next;
    await _store.write(next);
  }
}
