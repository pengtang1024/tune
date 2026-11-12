import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/artwork/artwork_image_provider.dart';
import 'package:tune/data/services/providers/artwork_cache_provider.dart';

/// The picture of the cover at [url].
///
/// The picture is fetched through the artwork cache, so a cover that was
/// fetched before comes from the disk instead of the network. The entry is
/// kept only while a thumb shows it: a library can pass thousands of covers,
/// and none of them should stay in the container after the row scrolled away.
final artworkImageProvider =
    Provider.autoDispose.family<ArtworkImageProvider, String>((ref, url) {
  final cache = ref.watch(artworkCacheProvider);
  return ArtworkImageProvider(url, cache: cache);
});
