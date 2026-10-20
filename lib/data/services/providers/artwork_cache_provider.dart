import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/artwork/artwork_cache.dart';
import 'package:tune/data/services/impl/artwork_cache.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';

/// The one place the covers of the tracks live in.
///
/// The cache is picked by platform: a build with a file system keeps every
/// cover on disk, the web build fetches it every time.
final artworkCacheProvider = Provider<ArtworkCache>((ref) {
  final paths = ref.watch(libraryPathsProvider);
  final cache = createArtworkCache(paths);
  ref.onDispose(cache.dispose);
  return cache;
});
