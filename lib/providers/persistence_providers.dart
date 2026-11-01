import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/impl/preference_store.dart';
import 'package:tune/data/services/persistence_service.dart';

/// The one place the preferences of the app live in: one file per preference
/// in the application support folder.
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  return createPersistenceService();
});
