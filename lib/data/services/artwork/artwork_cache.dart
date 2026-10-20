import 'dart:typed_data';

/// Keeps the covers of the tracks, so they do not have to be fetched again.
///
/// The cache owns the layout of its store. The interface only asks for the
/// bytes of a cover and never learns where it is kept, so the place of the
/// store can change without touching the interface that shows the covers.
abstract class ArtworkCache {
  /// The bytes of the cover at [url].
  ///
  /// The cover is taken from the local store when it was fetched before, so
  /// a restart does not fetch the same covers again. The call throws when
  /// the cover cannot be fetched.
  Future<Uint8List> bytesFor(String url);

  /// Releases the resources of the cache.
  void dispose();
}
