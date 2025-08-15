import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/data/services/impl/shared_preferences_service.dart';

/// SharedPreferences服务提供者
final sharedPreferencesServiceProvider = Provider<PersistenceService>((ref) {
  return SharedPreferencesService();
});
