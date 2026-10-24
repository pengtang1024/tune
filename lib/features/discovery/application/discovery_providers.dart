import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/discovery/data/discovery_feedback_store.dart';
import 'package:tune/features/discovery/domain/recommendation_engine.dart';
import 'package:tune/providers/persistence_providers.dart';

final discoveryFeedbackStoreProvider = Provider<DiscoveryFeedbackStore>((ref) {
  return DiscoveryFeedbackStore(ref.watch(persistenceServiceProvider));
});

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return const RecommendationEngine();
});
