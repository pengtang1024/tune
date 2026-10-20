import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/impl/preference_store.dart';
import 'package:tune/data/services/persistence_service.dart';

/// The one place the preferences of the app live in.
///
/// The store is picked by platform: a build with a file system keeps one file
/// per preference, the web build keeps them in the browser.
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  return createPersistenceService();
});
