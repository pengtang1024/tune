import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/artwork/artwork_cache.dart';
import 'package:tune/data/services/impl/artwork_cache.dart';

/// The one place the covers of the tracks live in.
///
/// The cache is picked by platform: a build with a file system keeps every
/// cover on disk, the web build fetches it every time.
final artworkCacheProvider = Provider<ArtworkCache>((ref) {
  final cache = createArtworkCache();
  ref.onDispose(cache.dispose);
  return cache;
});
