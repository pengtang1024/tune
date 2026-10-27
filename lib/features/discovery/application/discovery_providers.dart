import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/discovery/data/discovery_feedback_store.dart';
import 'package:tune/features/discovery/data/listening_signal_store.dart';
import 'package:tune/features/discovery/domain/recommendation_engine.dart';
import 'package:tune/data/services/providers/app_database_provider.dart';
import 'package:tune/providers/persistence_providers.dart';

final discoveryFeedbackStoreProvider = Provider<DiscoveryFeedbackStore>((ref) {
  return DiscoveryFeedbackStore(ref.watch(persistenceServiceProvider));
});

final discoveryArtistFeedbackStoreProvider =
    Provider<DiscoveryArtistFeedbackStore>((ref) {
      return DiscoveryArtistFeedbackStore(
        ref.watch(persistenceServiceProvider),
      );
    });

final listeningSignalStoreProvider = Provider<ListeningSignalStore>((ref) {
  return ListeningSignalStore(
    ref.watch(persistenceServiceProvider),
    database: () => ref.read(appDatabaseProvider.future),
  );
});

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return const RecommendationEngine();
});
