import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/data/services/impl/http_song_download_service.dart';

/// SongDownloadService 提供者
final songDownloadServiceProvider = Provider<SongDownloadService>((ref) {
  final service = HttpSongDownloadService();
  ref.onDispose(service.dispose);
  return service;
});
