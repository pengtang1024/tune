import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/favorites/data/favorites_store.dart';
import 'package:tune/features/favorites/domain/favorites_state.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

final favoritesStoreProvider = Provider<FavoritesStore>((ref) {
  return FavoritesStore(ref.watch(persistenceServiceProvider));
});

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, FavoritesState>(
      FavoritesController.new,
    );

/// Owns the tracks the user marked with a heart.
///
/// The controller is the one place that knows which tracks are liked: every
/// surface reads the state from here and asks the controller to mark a
/// track. Nothing else keeps a copy of the answer.
class FavoritesController extends Notifier<FavoritesState> {
  /// The write that is on its way to the store.
  ///
  /// Two marks in a row must not fight over the file: the second write has
  /// to land on top of the first one, or the store keeps the older set and
  /// the marks of the newer one are gone after a restart.
  Future<void> _writing = Future<void>.value();

  @override
  FavoritesState build() {
    return FavoritesState(ids: ref.read(favoritesStoreProvider).read());
  }

  /// Whether the track with this address is one of the favorites.
  bool contains(String id) => state.contains(id);

  /// Marks the track.
  ///
  /// A double click uses this: it may add a mark but never takes one away.
  /// A track that is already marked stays exactly as it is, so a double click
  /// on a favorite in the favorites page does not remove it.
  Future<void> mark(String id) async {
    if (id.isEmpty || state.contains(id)) return;

    final ids = {...state.ids, id};
    state = FavoritesState(ids: Set.unmodifiable(ids));
    final store = ref.read(favoritesStoreProvider);
    _writing = _writing.then((_) => _write(store, ids));
    await _writing;
  }

  /// Marks the track, or takes the mark away when it is already there.
  ///
  /// The heart is a single click and uses this: it is the only action that
  /// takes a mark away.
  Future<void> toggle(String id) async {
    if (id.isEmpty) return;

    final ids = {...state.ids};
    if (!ids.remove(id)) ids.add(id);

    state = FavoritesState(ids: Set.unmodifiable(ids));
    final store = ref.read(favoritesStoreProvider);
    _writing = _writing.then((_) => _write(store, ids));
    await _writing;
  }

  /// Puts the marks into the store.
  ///
  /// A write that fails is logged and does not break the chain: the marks
  /// after it still have to reach the store.
  Future<void> _write(FavoritesStore store, Set<String> ids) async {
    try {
      await store.write(ids);
    } catch (error, stackTrace) {
      Log.error('写入喜欢失败', stackTrace);
    }
  }
}
