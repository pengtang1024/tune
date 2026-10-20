import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_repository.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/providers/persistence_providers.dart';

/// Optional override used by tests and by future proxy/custom HTTP clients.
final musicSourceDioProvider = Provider<Dio?>((ref) => null);

final musicSourceStoreProvider = Provider<MusicSourceStore>((ref) {
  return MusicSourceStore(ref.watch(persistenceServiceProvider));
});

final musicPluginRepositoryProvider = Provider<MusicPluginRepository>((ref) {
  final repository = MusicPluginRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final musicSourceServiceProvider = Provider<MusicSourceService>((ref) {
  final service = MusicSourceService(
    scanner: ref.watch(crossPlatformMusicScannerProvider),
    store: ref.watch(musicSourceStoreProvider),
    pluginRepository: ref.watch(musicPluginRepositoryProvider),
    dio: ref.watch(musicSourceDioProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
