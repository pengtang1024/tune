/// The tracks the user marked with a heart.
///
/// A track is named by its canonical address: the path of a local file and
/// the `tune://` address of a track that comes from a source. The address
/// does not change when the library is scanned again, so a heart stays on
/// the track it was put on.
class FavoritesState {
  /// The addresses of the tracks that are marked.
  final Set<String> ids;

  const FavoritesState({this.ids = const {}});

  /// Whether the track with this address is one of the favorites.
  bool contains(String id) => ids.contains(id);

  /// How many tracks are marked.
  int get count => ids.length;
}
