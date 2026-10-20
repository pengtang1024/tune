import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/data/services/impl/http_song_download_service.dart';
import 'package:tune/data/services/providers/artwork_cache_provider.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';

/// SongDownloadService 提供者
final songDownloadServiceProvider = Provider<SongDownloadService>((ref) {
  final service = createSongDownloadService(
    paths: ref.watch(libraryPathsProvider),
    artwork: ref.watch(artworkCacheProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
