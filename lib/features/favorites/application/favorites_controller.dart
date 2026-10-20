import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/favorites/data/favorites_store.dart';
import 'package:tune/features/favorites/domain/favorites_state.dart';
import 'package:tune/providers/persistence_providers.dart';

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
  @override
  FavoritesState build() {
    return FavoritesState(ids: ref.read(favoritesStoreProvider).read());
  }

  /// Whether the track with this address is one of the favorites.
  bool contains(String id) => state.contains(id);

  /// Marks the track, or takes the mark away when it is already there.
  Future<void> toggle(String id) async {
    if (id.isEmpty) return;

    final ids = {...state.ids};
    if (!ids.remove(id)) ids.add(id);

    state = FavoritesState(ids: Set.unmodifiable(ids));
    await ref.read(favoritesStoreProvider).write(ids);
  }
}
